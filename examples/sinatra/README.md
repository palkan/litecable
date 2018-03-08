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

Run `Procfile.iodine` as in AnyCable example:

```sh
hivemind Procfile.iodine
```

Also it possible to run whole app(sinatra and litecable) with one Iodine server, like this:

```ruby
# config.ru
lib = File.expand_path("../../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require './app'
require './chat'

LiteCable.iodine!
LiteCable::Iodine.connection_factory = Chat::Connection

app = Rack::Builder.new do
  map '/' do
    run App
  end
  map '/cable' do
    run LiteCable::Iodine::RackApp
  end
end

run app
```

```sh
bundle exec iodine -v -p 9293
```
