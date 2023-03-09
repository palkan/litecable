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
  require "lite_cable/broadcast_adapters"
  require "lite_cable/anycable"

  class << self
    def config
      @config ||= Config.new
    end

    attr_accessor :channel_registry

    # Broadcast encoded message to the stream
    def broadcast(stream, message, coder: LiteCable.config.coder)
      broadcast_adapter.broadcast(stream, message, coder: coder)
    end

    def broadcast_adapter
      return @broadcast_adapter if defined?(@broadcast_adapter)
      self.broadcast_adapter = LiteCable.config.broadcast_adapter.to_sym
      @broadcast_adapter
    end

    def broadcast_adapter=(adapter)
      if adapter.is_a?(Symbol) || adapter.is_a?(Array)
        adapter = BroadcastAdapters.lookup_adapter(adapter)
      end

      unless adapter.respond_to?(:broadcast)
        raise ArgumentError, "BroadcastAdapter must implement #broadcast method. " \
                              "#{adapter.class} doesn't implement it."
      end

      @broadcast_adapter = adapter
    end
  end

  self.channel_registry = Channel::Registry
end
