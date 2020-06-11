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

## AnyCable usage

**NOTE:** AnyCable v1.0 is required.

This example also can be used with [AnyCable](http://anycable.io).

You need [`anycable-go`](https://github.com/anycable/anycable-go) installed.

Just run `Procfile` with your favourite tool ([hivemind](https://github.com/DarthSim/hivemind) or [overmind](https://github.com/DarthSim/overmind)):

```sh
hivemind
```

## Bonus: Testing via terminal

You can check play with this app from your terminal using [ACLI](https://github.com/palkan/acli). Here are the example commands:

```sh
# For AnyCable
acli -u localhost:9293 --headers="cookie:user=john" -c chat --channel-params "id:1"

# For Puma
acli -u localhost:9292 --headers="cookie:user=john" -c chat --channel-params "id:1"
```

To send a message type:

```sh
\p+ speak
Enter key: message
Enter value: <some text>
Enter key: <hit ENTER>
```
