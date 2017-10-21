# frozen_string_literal: true

module LiteCable
  module Server
    module ClientSocket
      # Handle socket subscriptions
      module Subscriptions
        def subscribe(channel, broadcasting)
          LiteCable::Server.subscribers_map
                           .add_subscriber(broadcasting, self, channel)
        end

        def unsubscribe(channel, broadcasting)
          LiteCable::Server.subscribers_map
                           .remove_subscriber(broadcasting, self, channel)
        end

        def unsubscribe_from_all(channel)
          LiteCable::Server.subscribers_map.remove_socket(self, channel)
        end
      end
    end
  end
end
