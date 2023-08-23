# Change log

## master (unreleased)

## 0.8.1 (2023-08-22)

- Handle closing socket already closed by server. ([@palkan][])

## 0.8.0 (2023-03-08)

- Allow using custom channel lookup logic. ([@palkan][])

- Ruby 2.7+ is required.

## 0.7.2 (2021-07-06)

- Fixed Ruby 3.0.1 compatibility.

## 0.7.1 (2021-01-06)

- Fix handling client disconnection during socket write. ([@palkan][])

## 0.7.0 (2020-01-07)

- Refactor AnyCable integration ([@palkan][])

Now you only need to set AnyCable broadcast adapter:

```ruby
LiteCable.broadcast_adapter = :any_cable
```

```sh
# or via env/config
LITECABLE_BROADCAST_ADAPTER=any_cable ruby my_app.rb
```

- Adapterize broadcast adapters ([@palkan][])

- Drop Ruby 2.4 support ([palkan][])

## 0.6.0 (2019-04-12) 🚀

- Drop Ruby 2.3 support ([@palkan][])

## 0.5.0 (2017-12-20)

- Upgrade for AnyCable 0.5.0 ([@palkan][])

## 0.4.1 (2017-02-04)

- Use `websocket-ruby` with sub-protocols support ([@palkan][])

## 0.4.0 (2017-01-29)

- Initial version. ([@palkan][])

[@palkan]: https://github.com/palkan
