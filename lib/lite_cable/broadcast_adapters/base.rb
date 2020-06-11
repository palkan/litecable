# frozen_string_literal: true

# frozen_string_literal: true

module LiteCable
  module BroadcastAdapters
    class Base
      def initialize(**options)
        @options = options
      end

      private

      attr_reader :options
    end
  end
end
