# frozen_string_literal: true

lib = File.expand_path("../../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require '../shared/app'
require '../shared//chat'

CABLE_URL = "/cable"

LiteCable.config.log_level = Logger::DEBUG

app = Rack::Builder.new do
  map '/' do
    run App
  end
end

require "iodine"

if ENV["REDIS_URL"]
  Iodine::PubSub.default = Iodine::PubSub::Redis.new(ENV["REDIS_URL"])
else
  puts "* No Redis, it's okay, pub/sub will still run on the whole process cluster."
end

require "lite_cable/iodine_server"

app.map '/cable' do
  use LiteCable::Server::Middleware, connection_class: Chat::Connection
  run proc { |_| [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
end

run app
