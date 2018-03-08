# coding: utf-8
# frozen_string_literal: true

# TODO:
# 1. broadcast извне сервера Iodine(например из экшена синатры) не работает.
# Мб решится, если настроить его через Redis pub\sub engine(быстро не завелось).
# 2. если запускать весь апп(синатру и ws) одним сервером Iodine, то пишет порой странные
# ошибки с памятью из c-extension - issue в iodine закинуть.

module LiteCable # :nodoc:
  # Iodine extensions
  module Iodine
    require "iodine"
    # LiteCable::Server needs for subscribers_map -
    # because Iodine don't have unsubscribe_from_all feature
    # and can broadcast only for whole stream without channel id in message
    require "lite_cable/server"

    BROADCASTING_STREAM = :litecable_broadcasting

    class << self
      attr_accessor :connection_factory
    end

    module Server # :nodoc:
      class << self
        def keepalive
          ::Iodine.run_every(3000) do
            # TODO: мб раскрыть приватную функцию ping_message из LiteCable::Server::HeartBeat?
            msg = ping_message(Time.now.to_i)
            ::Iodine::Websocket.each { |ws| ws.write(msg) }
          end
        end

        # Iodine runs multiple processes, each of which stores own subscriptions_map -
        # which sockets are subscribed for which channels and streams.
        # Iodine.publish sends an message to all processes, and here they make broadcast to
        # their own sockets.
        def setup_broadcast
          ::Iodine.subscribe(channel: LiteCable::Iodine::BROADCASTING_STREAM) do |_ch, json_msg|
            msg = JSON.parse(json_msg)
            LiteCable::Server.broadcast(msg["stream"], msg["payload"])
          end
        end

        private

        def ping_message(time)
          # what about coder?
          { type: LiteCable::INTERNAL[:message_types][:ping], message: time }.to_json
        end
      end
    end

    module Broadcasting # :nodoc:
      def broadcast(stream, message, coder: nil)
        coder ||= LiteCable.config.coder # not used now
        msg = {
          stream: stream,
          payload: message, # coder.encode(message)
        }
        # TODO: судя по всему в Anycable тоже ожидается только один кодер - json. Иначе
        # сервер поломается, так как расшифровывает message, чтобы добавить в него identifier
        # https://github.com/anycable/erlycable/blob/8600e61a256db2c48702e431c02958a871a25e51/src/erlycable_server.erl#L174
        # С iodine тоже сложно передать coder и впихнуть identifier, разве что через
        # сериализацию всего класса coder и его передачу процессам.
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
        handler.handle_open
      end

      def on_message(data)
        handler.handle_command(data)
      end

      # socket closed
      def on_close
        handler.handle_close
      end

      # server is shutting down, you can write to client
      def on_shutdown
        # not implemented, but maybe a good idea
      end
    end

    # Wrapper over socket for LiteCable::Connection::Base
    class ConnectionSocket
      attr_reader :env, :connection, :socket

      def initialize(env)
        @env = env
        # TODO: неприятная кольцевая зависимость классов
        # connection -> connection_socket -> websocket -> connection ;
        # env -> websocket ; connection_socket -> env
        @connection = LiteCable::Iodine.connection_factory.call(self)
        @socket = LiteCable::Iodine::Websocket.new(@connection)
      end

      ## LiteCable socket methods
      def request
        @request ||= Rack::Request.new(env)
      end

      def transmit(message)
        socket.write(message)
      end

      def subscribe(channel, stream)
        subscribers_map.add_subscriber(stream, self, channel) do
          socket.subscribe(channel: stream)
        end
      end

      def unsubscribe(channel, stream)
        subscribers_map.remove_subscriber(stream, self, channel) do
          unsubscribe_from_stream(stream)
        end
      end

      def unsubscribe_from_all(channel)
        subscribers_map.remove_socket(self, channel) do |stream|
          unsubscribe_from_stream(stream)
        end
      end

      def close
        socket.close
      end

      private
      def unsubscribe_from_stream(stream)
        subscription_id = socket.subscribed?(channel: stream)
        socket.unsubscribe(subscription_id)
      end

      def subscribers_map
        LiteCable::Server.subscribers_map
      end
    end

    module RackApp # :nodoc:
      def self.call(env)
        # 'upgrade.websocket?' - iodine rack extension
        unless env['upgrade.websocket?']
          return [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
        end

        conn = LiteCable::Iodine::ConnectionSocket.new(env)
        env['upgrade.websocket'] = conn.socket

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
    end
  end

  # Patch Lite Cable with Iodine functionality
  def self.iodine!
    LiteCable::Connection::Base.extend LiteCable::Iodine::Connection
    LiteCable.singleton_class.prepend LiteCable::Iodine::Broadcasting

    LiteCable::Iodine::Server.keepalive
    LiteCable::Iodine::Server.setup_broadcast
  end
end
