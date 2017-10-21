# frozen_string_literal: true

module LiteCable
  module Server
    # Rack middleware to hijack the socket
    class Middleware
      class HijackNotAvailable < RuntimeError; end

      def initialize(_app, connection_class:)
        @connection_class = connection_class
        @heart_beat = HeartBeat.new
      end

      def call(env)
        return [404, { 'Content-Type' => 'text/plain' }, ['Not Found']] unless
          env["HTTP_UPGRADE"] == 'websocket'

        raise HijackNotAvailable unless env['rack.hijack']

        env['rack.hijack'].call
        handshake = send_handshake(env)

        socket = ClientSocket::Base.new env, env['rack.hijack_io'], handshake.version
        init_connection socket
        init_heartbeat socket
        socket.listen
        [-1, {}, []]
      end

      private

      def send_handshake(env)
        handshake = WebSocket::Handshake::Server.new(
          protocols: LiteCable::INTERNAL[:protocols]
        )

        handshake.from_rack env
        env['rack.hijack_io'].write handshake.to_s
        handshake
      end

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
