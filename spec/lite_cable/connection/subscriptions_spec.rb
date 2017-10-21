# frozen_string_literal: true

require "spec_helper"

Class.new(LiteCable::Channel::Base) do
  identifier "subscription_test"

  def subscribed
    reject if params["reject"] == true
    @subscribed = true
  end

  def subscribed?
    @subscribed == true
  end

  def unsubscribed
    @unsubscribed = true
  end

  def unsubscribed?
    @unsubscribed == true
  end
end

Class.new(LiteCable::Channel::Base) do
  identifier "subscription_test2"
end

describe LiteCable::Connection::Subscriptions do
  let(:socket) { TestSocket.new }
  let(:connection) { LiteCable::Connection::Base.new(socket) }

  subject { described_class.new(connection) }

  describe "#add" do
    it "creates channel", :aggregate_failures do
      id = { channel: "subscription_test" }.to_json
      channel = subject.add(id)
      expect(channel).to be_subscribed
      expect(subject.identifiers).to include(id)
    end

    it "sends confirmation" do
      id = { channel: "subscription_test" }.to_json
      expect { subject.add(id) }.to change(socket.transmissions, :size).by(1)
      expect(socket.last_transmission).to eq("identifier" => id, "type" => "confirm_subscription")
    end

    it "handles params and identifier", :aggregate_failures do
      id = { channel: "subscription_test", id: 1, type: "test" }.to_json
      channel = subject.add(id)
      expect(channel.identifier).to eq id
      expect(channel.params).to eq("id" => 1, "type" => "test")
    end

    it "handles rejection", :aggregate_failures do
      id = { channel: "subscription_test", reject: true }.to_json
      channel = subject.add(id)
      expect(channel).to be_nil
      expect(subject.identifiers).not_to include(id)
      expect(socket.last_transmission).to eq("identifier" => id, "type" => "reject_subscription")
    end
  end

  describe "#remove" do
    let(:id) { { channel: "subscription_test" }.to_json }
    let!(:channel) { subject.add(id) }

    it "removes subscription and send cancel confirmation", :aggregate_failures do
      subject.remove(id)
      expect(channel).to be_unsubscribed
      expect(subject.identifiers).not_to include(id)
      expect(socket.last_transmission).to eq("identifier" => id, "type" => "cancel_subscription")
    end
  end

  describe "#remove_all" do
    let(:id) { { channel: "subscription_test" }.to_json }
    let(:id2) { { channel: "subscription_test2" }.to_json }

    let(:channel) { subject.add(id) }
    let(:channel2) { subject.add(id2) }

    it "removes all subscriptions and send confirmations", :aggregate_failures do
      expect(channel).to receive(:handle_unsubscribe)
      expect(channel2).to receive(:handle_unsubscribe)

      subject.remove_all
      expect(subject.identifiers).to eq([])
    end
  end

  describe "#execute_command" do
    it "handles subscribe" do
      expect(subject).to receive(:add).with("subscription_test")
      subject.execute_command("command" => "subscribe", "identifier" => "subscription_test")
    end

    it "handles unsubscribe" do
      expect(subject).to receive(:remove).with("subscription_test")
      subject.execute_command("command" => "unsubscribe", "identifier" => "subscription_test")
    end

    it "handles message" do
      channel = double("channel")
      expect(subject).to receive(:find).with("subscription_test").and_return(channel)
      expect(channel).to receive(:handle_action).with('{"action":"test"}')
      subject.execute_command("command" => "message", "identifier" => "subscription_test", "data" => { action: "test" }.to_json)
    end

    it "raises error on unknown command error" do
      expect { subject.execute_command("command" => "test") }.to raise_error(LiteCable::Connection::Subscriptions::UnknownCommandError)
    end
  end
end
