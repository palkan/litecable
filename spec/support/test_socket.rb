# frozen_string_literal: true

require "rack"
# Stub connection socket
class TestSocket
  attr_reader :transmissions, :streams

  def initialize(coder: LiteCable::Coders::JSON, env: {})
    @transmissions = []
    @streams = {}
    @coder = coder
    @env = env
  end

  def transmit(websocket_message)
    @transmissions << websocket_message
  end

  def last_transmission
    decode(@transmissions.last) if @transmissions.any?
  end

  def decode(websocket_message)
    @coder.decode websocket_message
  end

  def subscribe(channel, broadcasting)
    streams[channel] ||= []
    streams[channel] << broadcasting
  end

  def unsubscribe(channel, broadcasting)
    streams[channel]&.delete(broadcasting)
  end

  def unsubscribe_from_all(channel)
    streams.delete(channel)
  end

  def close
    @closed = true
  end

  def closed?
    @closed == true
  end

  def request
    @request ||= Rack::Request.new(@env)
  end
end
