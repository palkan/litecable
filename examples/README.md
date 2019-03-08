# Lite Cable Sinatra Demo

Sample chat application built with [Sinatra](http://www.sinatrarb.com) and Lite Cable.

## Usage

Go to built-in server example folder:
```sh
cd sinatra_builtin
```

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

Go to the Anycable example folder:
```sh
cd sinatra_anycable
```

Install dependencies:

```sh
bundle install
```

And just run `Procfile` with your favourite tool ([hivemind](https://github.com/DarthSim/hivemind) or [Foreman](http://ddollar.github.io/foreman/)):

```sh
hivemind
```

### Iodine usage

Go to the Iodine example folder:
```sh
cd sinatra_iodine
```

Install dependencies:

```sh
bundle install
```

and run `Procfile` as in AnyCable example:

```sh
hivemind
```
