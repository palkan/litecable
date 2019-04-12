# frozen_string_literal: true

require "spec_helper"

require "puma"

describe "Lite Cable server", :async do
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

  before(:all) do
    @server = ::Puma::Server.new(
      LiteCable::Server::Middleware.new(nil, connection_class: ServerTest::Connection),
      ::Puma::Events.strings
    )
    @server.add_tcp_listener "127.0.0.1", 3099
    @server.min_threads = 1
    @server.max_threads = 4

    @server_t = Thread.new { @server.run.join }
  end

  after(:all) do
    @server&.stop(true)
    @server_t&.join
  end

  let(:cookies) { "user=john" }
  let(:path) { "/?sid=123" }
  let(:client) { @client = SyncClient.new("ws://127.0.0.1:3099#{path}", cookies: cookies) }
  let(:logs) { ServerTest.logs }

  after { logs.clear }

  describe "connect" do
    it "receives welcome message" do
      expect(client.read_message).to eq("type" => "welcome")
    end

    context "when unauthorized" do
      let(:cookies) { "" }

      it "disconnects" do
        client.wait_for_close
        expect(client).to be_closed
      end
    end
  end

  describe "disconnect" do
    it "calls disconnect handlers" do
      expect(client.read_message).to eq("type" => "welcome")
      client.close
      client.wait_for_close
      expect(client).to be_closed

      wait { !logs.size.zero? }

      expect(logs.last).to include "john disconnected"
    end
  end

  describe "channels" do
    it "subscribes to channels and perform actions" do
      expect(client.read_message).to eq("type" => "welcome")

      client.send_message command: "subscribe", identifier: JSON.generate(channel: "echo")
      expect(client.read_message).to eq("identifier" => "{\"channel\":\"echo\"}", "type" => "confirm_subscription")

      client.send_message command: "message", identifier: JSON.generate(channel: "echo"), data: JSON.generate(action: "ding", message: "hello")
      expect(client.read_message).to eq("identifier" => "{\"channel\":\"echo\"}", "message" => {"dong" => "hello"})
    end

    it "unsubscribes from channels and receive cleanup messages" do
      expect(client.read_message).to eq("type" => "welcome")

      client.send_message command: "subscribe", identifier: JSON.generate(channel: "echo")
      expect(client.read_message).to eq("identifier" => "{\"channel\":\"echo\"}", "type" => "confirm_subscription")

      client.send_message command: "unsubscribe", identifier: JSON.generate(channel: "echo")
      expect(client.read_message).to eq("identifier" => "{\"channel\":\"echo\"}", "message" => {"message" => "Goodbye, john!"})
      expect(client.read_message).to eq("identifier" => "{\"channel\":\"echo\"}", "type" => "cancel_subscription")
    end
  end

  describe "broadcasts" do
    let(:client2) { @client2 = SyncClient.new("ws://127.0.0.1:3099/?sid=234", cookies: "user=alice") }

    let(:clients) { [client, client2] }

    before do
      concurrently(clients) do |c|
        expect(c.read_message).to eq("type" => "welcome")

        c.send_message command: "subscribe", identifier: JSON.generate(channel: "echo")
        expect(c.read_message).to eq("identifier" => "{\"channel\":\"echo\"}", "type" => "confirm_subscription")
      end
    end

    it "transmit messages to connected clients" do
      client.send_message command: "message", identifier: JSON.generate(channel: "echo"), data: JSON.generate(action: "bulk", message: "Good news, everyone!")

      concurrently(clients) do |c|
        expect(c.read_message).to eq("identifier" => "{\"channel\":\"echo\"}", "message" => {"message" => "Good news, everyone!", "from" => "john", "sid" => "123"})
      end

      client2.send_message command: "message", identifier: JSON.generate(channel: "echo"), data: JSON.generate(action: "bulk", message: "A-W-E-S-O-M-E")

      concurrently(clients) do |c|
        expect(c.read_message).to eq("identifier" => "{\"channel\":\"echo\"}", "message" => {"message" => "A-W-E-S-O-M-E", "from" => "alice", "sid" => "234"})
      end
    end
  end
end
