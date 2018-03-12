# coding: utf-8
# frozen_string_literal: true

# TODO:
# 1. broadcast извне сервера Iodine(например из экшена синатры) не работает.
# Мб решится, если настроить его через Redis pub\sub engine(быстро не завелось).
# 2. если запускать весь апп(синатру и ws) одним сервером Iodine, то пишет порой странные
# ошибки с памятью из c-extension - issue в iodine закинуть.
# 3. ConnectionSocket и RackApp это сильно похоже на ClientSocket и Middlerware из
# сервера. Неплохо бы их переюзать

module LiteCable # :nodoc:
  # Iodine extensions
  module Iodine
    require "iodine"
    # LiteCable::Server needs for subscribers_map -
    # because Iodine don't have unsubscribe_from_all feature
    # and can broadcast only for whole stream, without specific channel_id in message
    require "lite_cable/server"

    BROADCASTING_STREAM = :litecable_broadcasting

    class << self
      attr_accessor :connection_factory # мб не нужно, если запускать как Middleware
    end

    module Server # :nodoc:
      class << self
        # Iodine runs multiple processes, each of which stores own subscriptions_map -
        # which sockets are subscribed for which channels and streams.
        # Iodine.publish sends an message to all server processes, and here they make
        # broadcast to their own sockets.
        def setup_broadcast
          ::Iodine.subscribe(channel: LiteCable::Iodine::BROADCASTING_STREAM) do |_ch, json_msg|
            msg = JSON.parse(json_msg)
            LiteCable::Server.broadcast(msg["stream"], msg["payload"])
          end
        end
      end
    end

    module Broadcasting # :nodoc:
      def broadcast(stream, message, coder: nil)
        # TODO: судя по всему в Anycable тоже ожидается только один кодер - json. Иначе
        # сервер поломается, так как расшифровывает message, чтобы добавить в него identifier
        # https://github.com/anycable/erlycable/blob/8600e61a256db2c48702e431c02958a871a25e51/src/erlycable_server.erl#L174
        # С iodine тоже сложно передать coder и впихнуть identifier, разве что через
        # сериализацию всего класса coder и его передачу процессам.
        coder ||= LiteCable.config.coder # not used now
        msg = {
          stream: stream,
          payload: message, # coder.encode(message)
        }
        ::Iodine.publish(channel: LiteCable::Iodine::BROADCASTING_STREAM, message: msg.to_json)
      end
    end

    module Connection # :nodoc:
      def call(socket, **options)
        new(socket, **options)
      end
    end

    # Wrapper over Iodine websocket
    class Websocket
      attr_reader :handler

      def initialize(handler)
        @handler = handler
      end

      ## Iodine websocket methods
      def on_open
        handler.handle_open if handler.respond_to?(:handle_open)
      end

      def on_message(data)
        handler.handle_message(data) if handler.respond_to?(:handle_message)
      end

      # socket closed
      def on_close
        handler.handle_close if handler.respond_to?(:handle_close)
      end

      # server is shutting down, you can write to client
      def on_shutdown
        handler.handle_shutdown if handler.respond_to?(:handle_shudown)
      end
    end

    # Wrapper over socket for LiteCable::Connection::Base
    class ConnectionSocket
      include Logging
      include LiteCable::Server::ClientSocket::Subscriptions

      attr_reader :connection, :socket, :close_on_error

      def initialize(env)
        @env = env
        @socket = LiteCable::Iodine::Websocket.new(self)

        @open_handlers     = []
        @message_handlers  = []
        @close_handlers    = []
        @shutdown_handlers = []
        @error_handlers    = []

        @close_on_error = true
      end

      def prevent_close_on_error
        @close_on_error = false
      end

      def on_open(&block)
        @open_handlers << block
      end

      def on_message(&block)
        @message_handlers << block
      end

      def on_close(&block)
        @close_handlers << block
      end

      def on_shutdown(&block)
        @shutdown_handlers << block
      end

      def on_error(&block)
        @error_handlers << block
      end

      ## Websocket handlers
      def handle_open
        @open_handlers.each(&:call)
      end

      def handle_message
        @message_handlers.each do |h|
          begin
            h.call(data)
          rescue => e # rubocop: disable Style/RescueStandardError
            log(:error, "Socket receive failed: #{e} \n #{e.backtrace.join('\n')}")
            @error_handlers.each { |eh| eh.call(e, data) }
            close if close_on_error
          end
        end
      end

      def handle_close
        @close_handlers.each(&:call)
      end

      def handle_shutdown
        @shutdown_handlers.each(&:call)
      end

      ## LiteCable socket methods
      def request
        @request ||= Rack::Request.new(@env)
      end

      def transmit(message)
        socket.write(message)
      end

      def close
        socket.close
      end
    end

    module RackApp # :nodoc:
      def initialize(_app, connection_class:)
        # @connection_class = connection_class
        @heart_beat = HeartBeat.new
      end

      def call(env)
        # 'upgrade.websocket?' - iodine rack extension
        unless env['upgrade.websocket?']
          return [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
        end

        conn = LiteCable::Iodine::ConnectionSocket.new(env)
        env['upgrade.websocket'] = conn.socket # like socket.listen?

        init_connection(conn)
        init_heartbeat(conn)

        # iodine doesn't handle sec-websocket-protocol
        # https://github.com/boazsegev/iodine/blob/master/ext/iodine/websockets.c#L684
        # and likely doesn't handle old protocol versions too
        headers = {}
        protocol_header = env["HTTP_SEC_WEBSOCKET_PROTOCOL"]
        if protocol_header
          headers["Sec-WebSocket-Protocol"] = protocol_header.split(/ *, */).first
        end
        [0, headers, []]
      end

      def init_connection(socket)
        # connection = @connection_class.new(socket)
        connection = LiteCable::Iodine.connection_factory.call(socket)

        socket.on_open { connection.handle_open }
        socket.on_close { connection.handle_close }
        socket.on_message { |data| connection.handle_command(data) }
      end

      def init_heartbeat(socket)
        @heart_beat.add(socket)
        socket.on_close { @heart_beat.remove(socket) }
      end
    end
  end

  # Patch Lite Cable with Iodine functionality
  def self.iodine!
    LiteCable::Connection::Base.extend LiteCable::Iodine::Connection
    LiteCable.singleton_class.prepend LiteCable::Iodine::Broadcasting

    LiteCable::Iodine::Server.setup_broadcast
  end
end
