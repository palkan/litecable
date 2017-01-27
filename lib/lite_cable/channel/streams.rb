# frozen_string_literal: true
module LiteCable
  # rubocop:disable Metrics/LineLength
  module Channel
    # Streams allow channels to route broadcastings to the subscriber. A broadcasting is a pubsub queue where any data
    # placed into it is automatically sent to the clients that are connected at that time.

    # Most commonly, the streamed broadcast is sent straight to the subscriber on the client-side. The channel just acts as a connector between
    # the two parties (the broadcaster and the channel subscriber). Here's an example of a channel that allows subscribers to get all new
    # comments on a given page:
    #
    #   class CommentsChannel < ApplicationCable::Channel
    #     def follow(data)
    #       stream_from "comments_for_#{data['recording_id']}"
    #     end
    #
    #     def unfollow
    #       stop_all_streams
    #     end
    #   end
    #
    # Based on the above example, the subscribers of this channel will get whatever data is put into the,
    # let's say, `comments_for_45` broadcasting as soon as it's put there.
    #
    # An example broadcasting for this channel looks like so:
    #
    #   LiteCable.server.broadcast "comments_for_45", author: 'Donald Duck', content: 'Quack-quack-quack'
    #
    # You can stop streaming from all broadcasts by calling #stop_all_streams or use #stop_from to stop streaming broadcasts from the specified stream.
    module Streams
      # rubocop:enable Metrics/LineLength
      def handle_unsubscribe
        stop_all_streams
        super
      end

      # Start streaming from the named broadcasting pubsub queue.
      def stream_from(broadcasting)
        log(:debug) { log_fmt("Stream from #{broadcasting}") }
        connection.streams.add(identifier, broadcasting)
      end

      # Stop streaming from the named broadcasting pubsub queue.
      def stop_stream(broadcasting)
        log(:debug) { log_fmt("Stop stream from #{broadcasting}") }
        connection.streams.remove(identifier, broadcasting)
      end

      # Unsubscribes all streams associated with this channel from the pubsub queue.
      def stop_all_streams
        log(:debug) { log_fmt("Stop all streams") }
        connection.streams.remove_all(identifier)
      end
    end
  end
end
