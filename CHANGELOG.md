# Change log

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
