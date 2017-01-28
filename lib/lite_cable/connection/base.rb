# frozen_string_literal: true
module LiteCable
  # rubocop:disable Metrics/LineLength
  module Connection
    # A Connection object represents a client "connected" to the application.
    # It contains all of the channel subscriptions. Incoming messages are then routed to these channel subscriptions
    # based on an identifier sent by the consumer.
    # The Connection itself does not deal with any specific application logic beyond authentication and authorization.
    #
    # Here's a basic example:
    #
    #   module MyApplication
    #     class Connection < LiteCable::Connection::Base
    #       identified_by :current_user
    #
    #       def connect
    #         self.current_user = find_verified_user
    #       end
    #
    #       def disconnect
    #         # Any cleanup work needed when the cable connection is cut.
    #       end
    #
    #       private
    #         def find_verified_user
    #           User.find_by_identity(cookies[:identity]) ||
    #             reject_unauthorized_connection
    #         end
    #     end
    #   end
    #
    # First, we declare that this connection can be identified by its current_user. This allows us to later be able to find all connections
    # established for that current_user (and potentially disconnect them). You can declare as many
    # identification indexes as you like. Declaring an identification means that an attr_accessor is automatically set for that key.
    #
    # Second, we rely on the fact that the connection is established with the cookies from the domain being sent along. This makes
    # it easy to use cookies that were set when logging in via a web interface to authorize the connection.
    #
    class Base
      # rubocop:enable Metrics/LineLength
      include Authorization
      prepend Identification
      include Logging

      attr_reader :subscriptions, :streams, :coder

      def initialize(socket, coder: nil)
        @socket = socket
        @coder = coder || LiteCable.config.coder

        @subscriptions = Subscriptions.new(self)
        @streams = Streams.new(socket)
      end

      def handle_open
        connect if respond_to?(:connect)
        send_welcome_message
        log(:debug) { log_fmt("Opened") }
      rescue UnauthorizedError
        log(:debug) { log_fmt("Authorization failed") }
        close
      end

      def handle_close
        disconnected!
        subscriptions.remove_all

        disconnect if respond_to?(:disconnect)
        log(:debug) { log_fmt("Closed") }
      end

      def handle_command(websocket_message)
        command = decode(websocket_message)
        subscriptions.execute_command command
      rescue Subscriptions::Error, Channel::Error, Channel::Registry::Error => e
        log(:error, log_fmt("Connection command failed: #{e}"))
        close
      end

      def transmit(cable_message)
        return if disconnected?
        socket.transmit encode(cable_message)
      end

      def close
        socket.close
      end

      # Rack::Request instance of underlying socket
      def request
        socket.request
      end

      # Request cookies
      def cookies
        request.cookies
      end

      def disconnected?
        @_disconnected == true
      end

      private

      attr_reader :socket

      def disconnected!
        @_disconnected = true
      end

      def send_welcome_message
        # Send welcome message to the internal connection monitor channel.
        # This ensures the connection monitor state is reset after a successful
        # websocket connection.
        transmit type: LiteCable::INTERNAL[:message_types][:welcome]
      end

      def encode(cable_message)
        coder.encode cable_message
      end

      def decode(websocket_message)
        coder.decode websocket_message
      end

      def log_fmt(msg)
        "[connection:#{identifier}] #{msg}"
      end
    end
  end
end
