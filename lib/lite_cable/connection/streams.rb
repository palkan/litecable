# frozen_string_literal: true
module LiteCable
  module Connection
    # Manage the connection streams
    class Streams
      attr_reader :socket

      def initialize(socket)
        @socket = socket
      end

      # Start streaming from broadcasting to the channel.
      def add(channel_id, broadcasting)
        socket.subscribe(channel_id, broadcasting)
      end

      # Stop streaming from broadcasting to the channel.
      def remove(channel_id, broadcasting)
        socket.unsubscribe(channel_id, broadcasting)
      end

      # Stop all streams for the channel
      def remove_all(channel_id)
        socket.unsubscribe_from_all(channel_id)
      end
    end
  end
end
