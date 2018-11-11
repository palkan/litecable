# frozen_string_literal: true

module LiteCable
  module Server
    class Middleware # :nodoc:
      BROADCASTING_STREAM = :litecable_broadcasting

      def initialize(_app, connection_class:)
        @connection_class = connection_class
        @heart_beat = Server::HeartBeat.new
        setup_broadcast
      end

      def call(env)
        unless env['rack.upgrade?'] == :websocket
          return [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
        end

        socket = ClientSocket::Base.new

        init_connection socket
        init_heartbeat socket

        env['rack.upgrade'] = socket

        [0, { 'Sec-WebSocket-Protocol': LiteCable::INTERNAL[:protocols].first }, []]
      end

      private

      # rubocop:disable Security/MarshalLoad
      def setup_broadcast
        Iodine.subscribe(BROADCASTING_STREAM) do |_ch, json_msg|
          msg = JSON.parse(json_msg)
          coder = msg['coder'] ? Marshal.load(msg['coder']) : LiteCable.config.coder

          Server.subscribers_map.broadcast(msg.fetch('stream'), msg.fetch('payload'), coder)
        end
      end
      # rubocop:enable Security/MarshalLoad

      def init_connection(socket)
        connection = @connection_class.new(socket)

        socket.onopen { connection.handle_open }
        socket.onclose { connection.handle_close }
        socket.onmessage { |data| connection.handle_command(data) }
      end

      def init_heartbeat(socket)
        @heart_beat.add(socket)
        socket.onclose { @heart_beat.remove(socket) }
      end
    end
  end
end
