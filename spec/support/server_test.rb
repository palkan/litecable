# frozen_string_literal: true

module ServerTest
  class << self
    def logs
      @logs ||= []
    end
  end

  class Connection < LiteCable::Connection::Base
    identified_by :user, :sid

    def connect
      reject_unauthorized_connection unless cookies["user"]
      @user = cookies["user"]
      @sid = request.params["sid"]
    end

    def disconnect
      ServerTest.logs << "#{user} disconnected"
    end
  end

  class EchoChannel < LiteCable::Channel::Base
    identifier :echo

    def subscribed
      stream_from "global"
    end

    def unsubscribed
      transmit message: "Goodbye, #{user}!"
    end

    def ding(data)
      transmit(dong: data["message"])
    end

    def delay(data)
      sleep 1
      transmit(dong: data["message"])
    end

    def bulk(data)
      LiteCable.broadcast "global", message: data["message"], from: user, sid: sid
    end
  end
end
