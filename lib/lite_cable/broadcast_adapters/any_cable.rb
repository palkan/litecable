# frozen_string_literal: true

module LiteCable
  module BroadcastAdapters
    class AnyCable < Base
      def broadcast(stream, message, coder:)
        ::AnyCable.broadcast stream, coder.encode(message)
      end
    end
  end
end
