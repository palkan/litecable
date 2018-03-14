# coding: utf-8
# frozen_string_literal: true

# TODO:
# 1. broadcast работает только изнутри сервера Iodine(т.е. если хочется его из экшенов
# синатры, а не из канала, то надо синатру и каналы запускать сервером iodine).
# Заработает снаружи, если сделать что-то из этого:
# a) сделать http путь типо /broadcast изнутри iodine rack.
# b) запустить и синатру и каналы через сервер iodine(т.е. пуму убрать)
# c) юзать Redis как pubsub engine И сделать доп. фикс -
# или делать руками PUBLISH в redis,
# или если Iodine научится запускаться без запуска сервера, как клиент к pubsub'у.
#
# 2. puts не работает внутри rack и сообщений с вебсокетов.


module LiteCable # :nodoc:
  # Iodine extensions
  module Iodine
    # LiteCable::Server needs for subscribers_map -
    # because Iodine don't have unsubscribe_from_all feature
    # and can broadcast only for whole stream, without specific channel_id in message
    require "lite_cable/server"

    BROADCASTING_STREAM = :litecable_broadcasting

    module Server # :nodoc:
      class << self
        # Iodine runs multiple processes, each of which stores own subscriptions_map -
        # which sockets are subscribed for which channels and streams.
        # Iodine.publish sends an message to all server processes, and here they make
        # broadcast to their own sockets.
        def setup_broadcast
          ::Iodine.subscribe(channel: LiteCable::Iodine::BROADCASTING_STREAM) do |_ch, json_msg|
            msg = JSON.parse(json_msg)
            # rubocop: disable Security/MarshalLoad - security risk only if pubsub engine
            # is Redis and it has open access to internet
            coder = msg['coder'] ? Marshal.load(msg['coder']) : LiteCable.config.coder
            # rubocop: enable Security/MarshalLoad
            LiteCable::Server.broadcast(msg["stream"], msg["payload"], coder: coder)
          end
        end
      end
    end

    module Broadcasting # :nodoc:
      def broadcast(stream, message, coder: nil)
        msg = { stream: stream, payload: message }
        msg[:coder] = Marshal.dump(coder) if coder
        ::Iodine.publish(channel: LiteCable::Iodine::BROADCASTING_STREAM, message: msg.to_json)
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
      # TODO: not really cool, and besides, there is still a duplication with ClientSocket:
      # 'request' and 'close_on_error'
      include LiteCable::Server::ClientSocket::Handlers

      attr_reader :socket, :close_on_error

      def initialize(env)
        @env = env
        @socket = LiteCable::Iodine::Websocket.new(self)

        @close_on_error = true

        init_handlers
      end

      def prevent_close_on_error
        @close_on_error = false
      end

      ## Websocket handlers
      def handle_open
        @open_handlers.each(&:call)
      end

      def handle_message(data)
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

    class RackApp < LiteCable::Server::Middleware # :nodoc:
      def call(env)
        # 'upgrade.websocket?' - iodine rack extension
        unless env['upgrade.websocket?']
          return [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
        end

        conn = LiteCable::Iodine::ConnectionSocket.new(env)
        env['upgrade.websocket'] = conn.socket

        init_connection(conn)
        init_heartbeat(conn)

        # iodine doesn't handle sec-websocket-protocol
        # https://github.com/boazsegev/iodine/blob/master/ext/iodine/websockets.c#L684
        # and likely doesn't handle old protocol versions too
        protocol = env["HTTP_SEC_WEBSOCKET_PROTOCOL"]&.split(/ *, */)&.first
        headers = protocol ? { 'Sec-WebSocket-Protocol': protocol } : {}
        [0, headers, []]
      end
    end
  end

  # Patch Lite Cable with Iodine functionality
  def self.iodine!
    LiteCable.singleton_class.prepend LiteCable::Iodine::Broadcasting

    LiteCable::Iodine::Server.setup_broadcast
  end
end
