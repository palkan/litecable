# frozen_string_literal: true
require "lite_cable/version"
require "lite_cable/internal"

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

  class << self
    def config
      @config ||= Config.new
    end
  end
end
