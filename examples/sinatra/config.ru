# frozen_string_literal: true

require_relative "config/environment"

app = Rack::Builder.new do
  map "/" do
    run App
  end
end

unless ENV["ANYCABLE"]
  # Start built-in rack hijack middleware to serve websockets
  require "lite_cable/server"

  app.map "/cable" do
    use LiteCable::Server::Middleware, connection_class: Chat::Connection
    run(proc { |_| [200, {"Content-Type" => "text/plain"}, ["OK"]] })
  end
end

run app
