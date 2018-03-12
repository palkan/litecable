#!/usr/bin/env ruby
# frozen_string_literal: true

lib = File.expand_path("../../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "./chat"
require "rack"

LiteCable.config.log_level = Logger::DEBUG

# Turn Iodine compatibility mode
# Iodine.default_pubsub = Iodine::PubSub::RedisEngine.new('localhost')
LiteCable.iodine!

app = Rack::Builder.new do
  map '/cable' do
    use LiteCable::Iodine::RackApp, connection_class: Chat::Connection
    run proc { |_| [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  end
end

run app
