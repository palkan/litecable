# frozen_string_literal: true

module LiteCable
  module Server
    # Sends pings to sockets
    class HeartBeat
      BEAT_INTERVAL = 3

      def initialize
        @sockets = []
        run
      end

      def add(socket)
        @sockets << socket
      end

      def remove(socket)
        @sockets.delete(socket)
      end

      def stop
        @stopped = true
      end

      # rubocop: disable Metrics/MethodLength
      def run
        Thread.new do
          Thread.current.abort_on_exception = true
          loop do
            break if @stopped

            unless @sockets.empty?
              msg = ping_message Time.now.to_i
              @sockets.each do |socket|
                socket.transmit msg
              end
            end

            sleep BEAT_INTERVAL
          end
        end
      end
      # rubocop: enable Metrics/MethodLength

      private

      def ping_message(time)
        {type: LiteCable::INTERNAL[:message_types][:ping], message: time}.to_json
      end
    end
  end
end
