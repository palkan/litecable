# frozen_string_literal: true

require "spec_helper"

class TestStreamsChannel < LiteCable::Channel::Base
  attr_reader :all_stopped

  def subscribed
    stream_from "notifications_#{user}"
  end

  def follow(data)
    stream_from "chat_#{data['id']}"
  end

  def unfollow(data)
    stop_stream "chat_#{data['id']}"
  end

  def stop_all_streams
    super
    @all_stopped = true
  end
end

describe TestStreamsChannel do
  let(:user) { "john" }
  let(:socket) { TestSocket.new }
  let(:connection) { TestConnection.new(socket, identifiers: { "user" => user }.to_json) }
  let(:params) { {} }

  subject { described_class.new(connection, "test", params) }

  describe "#stream_from" do
    it "subscribes channel to stream" do
      subject.handle_subscribe
      expect(socket.streams["test"]).to eq(["notifications_john"])
    end
  end

  describe "#stop_stream" do
    it "unsubscribes channel from stream", :aggregate_failures do
      subject.handle_action({ "action" => "follow", "id" => 1 }.to_json)
      expect(socket.streams["test"]).to eq(["chat_1"])

      subject.handle_action({ "action" => "unfollow", "id" => 1 }.to_json)
      expect(socket.streams["test"]).to eq([])
    end
  end

  describe "#stop_all_streams" do
    it "call stop_all_streams on unsubscribe", :aggregate_failures do
      subject.handle_subscribe
      expect(socket.streams["test"]).to eq(["notifications_john"])

      subject.handle_unsubscribe
      expect(subject.all_stopped).to eq true
      expect(socket.streams["test"]).to be_nil
    end
  end
end
