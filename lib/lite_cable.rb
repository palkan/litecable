# frozen_string_literal: true

require "lite_cable/version"
require "lite_cable/internal"
require "lite_cable/logging"

# Lightwieght ActionCable implementation.
#
# Contains application logic (channels, streams, broadcasting) and
# also (optional) Rack hijack based server (suitable only for development and test).
#
# Compatible with AnyCable (for production usage).
module LiteCable
  require "lite_cable/connection"
  require "lite_cable/channel"
  require "lite_cable/coders"
  require "lite_cable/config"
  require "lite_cable/anycable"

  class << self
    def config
      @config ||= Config.new
    end

    # Broadcast encoded message to the stream
    def broadcast(*args)
      LiteCable::Server.broadcast(*args)
    end
  end
end
