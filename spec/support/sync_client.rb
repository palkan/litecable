# frozen_string_literal: true

# Synchronous websocket client
# Based on https://github.com/rails/rails/blob/v5.0.1/actioncable/test/client_test.rb
class SyncClient
  require "websocket-client-simple"
  require "concurrent"

  WAIT_WHEN_EXPECTING_EVENT = 5
  WAIT_WHEN_NOT_EXPECTING_EVENT = 0.5

  attr_reader :pings

  def initialize(url, cookies: '')
    messages = @messages = Queue.new
    closed = @closed = Concurrent::Event.new
    has_messages = @has_messages = Concurrent::Semaphore.new(0)
    pings = @pings = Concurrent::AtomicFixnum.new(0)

    open = Concurrent::Promise.new

    @ws = WebSocket::Client::Simple.connect(
      url,
      headers: {
        'COOKIE' => cookies
      }
    ) do |ws|
      ws.on(:error) do |event|
        event = RuntimeError.new(event.message) unless event.is_a?(Exception)

        if open.pending?
          open.fail(event)
        else
          messages << event
          has_messages.release
        end
      end

      ws.on(:open) do |event|
        open.set(true)
      end

      ws.on(:message) do |event|
        if event.type == :close
          closed.set
        else
          message = JSON.parse(event.data)
          if message["type"] == "ping"
            pings.increment
          else
            messages << message
            has_messages.release
          end
        end
      end

      ws.on(:close) do |event|
        closed.set
      end
    end

    open.wait!(WAIT_WHEN_EXPECTING_EVENT)
  end

  def read_message
    @has_messages.try_acquire(1, WAIT_WHEN_EXPECTING_EVENT)

    msg = @messages.pop(true)
    raise msg if msg.is_a?(Exception)

    msg
  end

  def read_messages(expected_size = 0)
    list = []
    loop do
      if @has_messages.try_acquire(1, list.size < expected_size ? WAIT_WHEN_EXPECTING_EVENT : WAIT_WHEN_NOT_EXPECTING_EVENT)
        msg = @messages.pop(true)
        raise msg if msg.is_a?(Exception)

        list << msg
      else
        break
      end
    end
    list
  end

  def send_message(message)
    @ws.send(JSON.generate(message))
  end

  def close
    sleep WAIT_WHEN_NOT_EXPECTING_EVENT

    unless @messages.empty?
      raise "#{@messages.size} messages unprocessed"
    end

    @ws.close
    wait_for_close
  end

  def wait_for_close
    @closed.wait(WAIT_WHEN_EXPECTING_EVENT)
  end

  def closed?
    @closed.set?
  end
end
