# Lite Cable Sinatra Demo

Sample chat application built with [Sinatra](http://www.sinatrarb.com) and Lite Cable.

## Usage

Install dependencies:

```sh
bundle install
```

Run server:

```sh
bundle exec puma
```

Open your browser at [localhost:9292](http://localhost:9292), enter your name and a chat room ID (anything you want).

Then open another session (another browser, incognito window) and repeat all steps using the same room ID.

Now you can chat with yourself!


## Integrations
This example also can be used with [AnyCable](http://anycable.io) or [Iodine](https://github.com/boazsegev/iodine).

### AnyCable usage
You need [`anycable-go`](https://github.com/anycable/anycable-go) installed.

Just run `Procfile` with your favourite tool ([hivemind](https://github.com/DarthSim/hivemind) or [Foreman](http://ddollar.github.io/foreman/)):

```sh
hivemind
```

### Iodine usage

Iodine integration basically is a rack middleware. So you can run it like this:

```ruby
require "rack"

# initialize the Redis engine if needed
if ENV["REDIS_URL"]
  uri = URI(ENV["REDIS_URL"])
  Iodine.default_pubsub = Iodine::PubSub::RedisEngine.new(uri.host, uri.port, 0, uri.password)
else
  puts "* No Redis, it's okay, pub/sub will still run inside connection"
end

LiteCable.iodine!

app = Rack::Builder.new do
  map '/cable' do
    use LiteCable::Iodine::RackApp, connection_class: My::App::Connection
    run proc { |_| [200, { 'Content-Type' => 'text/plain' }, ['OK']] }
  end
end

run app
```

For more real-life example run `Procfile.iodine` like in AnyCable example:

```sh
hivemind Procfile.iodine
```
