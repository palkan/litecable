# frozen_string_literal: true

module LiteCable
  module Server
    # From https://github.com/rails/rails/blob/v5.0.1/actioncable/lib/action_cable/subscription_adapter/subscriber_map.rb
    class SubscribersMap
      attr_reader :streams, :sockets

      def initialize
        @streams = Hash.new do |streams, stream_id|
          streams[stream_id] = Hash.new { |channels, channel_id| channels[channel_id] = [] }
        end
        @sockets = Hash.new { |h, k| h[k] = [] }
        @sync = Mutex.new
      end

      def add_subscriber(stream, socket, channel)
        @sync.synchronize do
          @streams[stream][channel] << socket
          @sockets[socket] << [channel, stream]
        end
      end

      def remove_subscriber(stream, socket, channel)
        @sync.synchronize do
          @streams[stream][channel].delete(socket)
          @sockets[socket].delete([channel, stream])
          cleanup stream, socket, channel
        end
      end

      def remove_socket(socket, channel)
        list = @sync.synchronize do
          return unless @sockets.key?(socket)

          @sockets[socket].dup
        end

        list.each do |(channel_id, stream)|
          remove_subscriber(stream, socket, channel) if channel == channel_id
        end
      end

      def broadcast(stream, message, coder)
        list = @sync.synchronize do
          return unless @streams.key?(stream)

          @streams[stream].to_a
        end

        list.each do |(channel_id, sockets)|
          cmessage = channel_message(channel_id, message, coder)
          sockets.each { |s| s.transmit cmessage }
        end
      end

      private

      def cleanup(stream, socket, channel)
        @streams[stream].delete(channel) if @streams[stream][channel].empty?
        @streams.delete(stream) if @streams[stream].empty?
        @sockets.delete(socket) if @sockets[socket].empty?
      end

      def channel_message(channel_id, message, coder)
        coder.encode(identifier: channel_id, message: message)
      end
    end
  end
end
