# frozen_string_literal: true

require 'iodine'

module LiteCable
  module Server # :nodoc:
    require "lite_cable/server/subscribers_map"
    require "lite_cable/server/heart_beat"
    require "lite_cable/iodine_server/client_socket"
    require "lite_cable/iodine_server/middleware"

    class << self
      attr_accessor :subscribers_map

      # Broadcast encoded message to the stream
      def broadcast(stream, message, coder: nil)
        msg = { stream: stream, payload: message }
        msg[:coder] = Marshal.dump(coder) if coder

        Iodine.publish(LiteCable::Server::Middleware::BROADCASTING_STREAM, msg.to_json)
      end
    end

    self.subscribers_map = Server::SubscribersMap.new
  end
end
