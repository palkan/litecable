# frozen_string_literal: true

module LiteCable
  # Rack middleware to hijack sockets.
  #
  # Uses thread-per-connection model (thus recommended only for development and test usage).
  #
  # Inspired by https://github.com/ngauthier/tubesock/blob/master/lib/tubesock.rb
  module Server
    require "websocket"
    require "lite_cable/server/subscribers_map"
    require "lite_cable/server/client_socket"
    require "lite_cable/server/heart_beat"
    require "lite_cable/server/middleware"

    class << self
      attr_accessor :subscribers_map
    end

    self.subscribers_map = SubscribersMap.new
  end
end
