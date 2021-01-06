# frozen_string_literal: true

module LiteCable
  module Channel
    # Stores channels identifiers and corresponding classes.
    module Registry
      class Error < StandardError; end

      class AlreadyRegisteredError < Error; end

      class UnknownChannelError < Error; end

      class << self
        def add(id, channel_class)
          raise AlreadyRegisteredError if find(id)

          channels[id] = channel_class
        end

        def find(id)
          channels[id]
        end

        def find!(id)
          channel_class = find(id)
          raise UnknownChannelError unless channel_class

          channel_class
        end

        private

        def channels
          @channels ||= {}
        end
      end
    end
  end
end
