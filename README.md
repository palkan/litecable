[![Gem Version](https://badge.fury.io/rb/litecable.svg)](https://rubygems.org/gems/litecable)
[![Build](https://github.com/palkan/litecable/workflows/Build/badge.svg)](https://github.com/palkan/litecable/actions)

# Lite Cable

Lightweight ActionCable implementation.

Contains application logic (channels, streams, broadcasting) and also (optional) Rack hijack based server (suitable only for development and test due to its simplicity).

Compatible with [AnyCable](http://anycable.io) (for production usage).

<a href="https://evilmartians.com/">
<img src="https://evilmartians.com/badges/sponsored-by-evil-martians.svg" alt="Sponsored by Evil Martians" width="236" height="54"></a>

## Examples

- [Sinatra LiteCable Chat](https://github.com/palkan/litecable/tree/master/examples/sinatra)

- [Connecting LiteCable to Hanami](http://gabrielmalakias.com.br/ruby/hanami/iot/2017/05/26/websockets-connecting-litecable-to-hanami.html) by [@GabrielMalakias](https://github.com/GabrielMalakias)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "litecable"
```

And run `bundle install`.

## Usage

Please, checkout [Action Cable guides](http://guides.rubyonrails.org/action_cable_overview.html) for general information. Lite Cable aims to be compatible with Action Cable as much as possible without the loss of simplicity and _lightness_.

You can use Action Cable javascript client without any change (precompiled version can be found [here](https://github.com/palkan/litecable/tree/master/examples/sinatra/assets/cable.js)).

Here are the differences:

- Use `LiteCable::Connection::Base` as a base class for your connection (instead of `ActionCable::Connection::Base`)

- Use `LiteCable::Channel::Base` as a base class for your channels (instead of `ActionCable::Channel::Base`)

- Use `LiteCable.broadcast` to broadcast messages (instead of `ActionCable.server.broadcast`)

- Explicitly specify channels names:

```ruby
class MyChannel < LiteCable::Channel::Base
  # Use this id in your client to create subscriptions
  identifier :chat
end
```

```js
App.cable.subscriptions.create('chat', ...)
```

### Using a custom channel registry

Alternatively to eager loading all channel classes and providing identifiers, you can build a custom _channel registry_ object, which can perform channel class lookups:

```ruby
# DummyRegistry which always returns a predefined channel class
class DummyRegistry
  def lookup(channel_id)
    DummyChannel
  end
end

LiteCable.channel_registry = DummyRegistry.new
```

### Using built-in server (middleware)

Lite Cable comes with a simple Rack middleware for development/testing usage.
To use Lite Cable server:

- Add `gem "websocket"` to your Gemfile

- Add `require "lite_cable/server"`

- Add `LiteCable::Server::Middleware` to your Rack stack, for example:

```ruby
Rack::Builder.new do
  map "/cable" do
    # You have to specify your app's connection class
    use LiteCable::Server::Middleware, connection_class: App::Connection
    run proc { |_| [200, {"Content-Type" => "text/plain"}, ["OK"]] }
  end
end
```

### Using with AnyCable

Lite Cable is AnyCable-compatible out-of-the-box.

If AnyCable gem is loaded, you don't need to configure Lite Cable at all.

Otherwise, you must configure broadcast adapter manually:

```ruby
LiteCable.broadcast_adapter = :any_cable
```

You can also do this via configuration, e.g., env var (`LITECABLE_BROADCAST_ADAPTER=any_cable`) or `broadcast_adapter: any_cable` in a YAML config.

**At the AnyCable side**, you must configure a connection factory:

```ruby
AnyCable.connection_factory = MyApp::Connection
```

Then run AnyCable along with the app:

```sh
bundle exec anycable

# add -r option to load the app if it's not ./config/anycable.rb or ./config/environment.rb
bundle exec anycable -r ./my_app.rb
```

See [Sinatra example](https://github.com/palkan/litecable/tree/master/examples/sinatra) for more.

### Configuration

Lite Cable uses [anyway_config](https://github.com/palkan/anyway_config) for configuration.

See [config](https://github.com/palkan/litecable/blob/master/lib/lite_cable/config.rb) for available options.

### Unsupported features

- Channel callbacks (`after_subscribe`, etc)

- Stream callbacks (`stream_from "xyz" { |msg| ... }`)

- Periodical timers

- Remote connections.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/palkan/litecable](https://github.com/palkan/litecable).

## License

The gem is available as open source under the terms of the [MIT License](./LICENSE.txt).
