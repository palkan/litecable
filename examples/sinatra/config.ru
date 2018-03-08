# frozen_string_literal: true

lib = File.expand_path("../../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require './app'
require './chat'

LiteCable.config.log_level = Logger::DEBUG

app = Rack::Builder.new do
  map '/' do
    run App
  end
end

if ENV['ANYCABLE']
  # Turn AnyCable compatibility mode
  LiteCable.anycable!
elsif ENV['IODINE']
  # Turn Iodine compatibility mode
  LiteCable.iodine!
else
  require "lite_cable/server"

  app.map '/cable' do
    use LiteCable::Server::Middleware, connection_class: Chat::Connection
    run proc { |_| [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  end
end

run app
