# frozen_string_literal: true
lib = File.expand_path("../../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require './app'
require './chat'
require "lite_cable/server"

LiteCable.config.log_level = Logger::DEBUG

app = Rack::Builder.new do
  map '/' do
    run App
  end

  map '/cable' do
    use LiteCable::Server::Middleware, connection_class: Chat::Connection
    run proc { |_| [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  end
end

run app
