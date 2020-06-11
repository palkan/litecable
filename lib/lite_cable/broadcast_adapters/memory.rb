# frozen_string_literal: true

module LiteCable
  module BroadcastAdapters
    class Memory < Base
      def broadcast(stream, message, coder:)
        Server.subscribers_map.broadcast stream, message, coder
      end
    end
  end
end
