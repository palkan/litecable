# frozen_string_literal: true
require "spec_helper"

class TestChannel < LiteCable::Channel::Base
  attr_reader :subscribed, :unsubscribed, :follows, :received

  def subscribed
    reject if params["reject"]
    @subscribed = true
  end

  def unsubscribed
    @unsubscribed = true
  end

  def receive(data)
    @received = data
  end

  def follow_all
    @follows = true
  end

  def follow(data)
    transmit follow_id: data["id"]
  end
end

describe TestChannel do
  let(:user) { "john" }
  let(:socket) { TestSocket.new }
  let(:connection) { TestConnection.new(socket, identifiers: { "user" => user }.to_json) }
  let(:params) { {} }

  subject { described_class.new(connection, "test", params) }

  describe "connection identifiers" do
    specify { expect(subject.user).to eq "john" }
  end

  describe "#handle_subscribe" do
    it "calls #subscribed method" do
      subject.handle_subscribe
      expect(subject.subscribed).to eq true
    end

    context "when rejects" do
      let(:params) { { "reject" => true } }

      it "raises error" do
        expect { subject.handle_subscribe }.to raise_error(LiteCable::Channel::RejectedError)
      end
    end
  end

  describe "#handle_unsubscribe" do
    it "calls #unsubscribed method" do
      subject.handle_unsubscribe
      expect(subject.unsubscribed).to eq true
    end
  end

  describe "#handle_action" do
    it "call actions without parameters" do
      subject.handle_action({ "action" => "follow_all" }.to_json)
      expect(subject.follows).to eq true
    end

    it "call actions with parameters" do
      expect { subject.handle_action({ "action" => "follow", "id" => 15 }.to_json) }.to change(socket.transmissions, :size).by(1)
      expect(socket.last_transmission).to eq("message" => { "follow_id" => 15 }, "identifier" => "test")
    end

    it "calls 'receive' when no action param" do
      subject.handle_action({ "message" => "Recieve me!" }.to_json)
      expect(subject.received).to eq("message" => "Recieve me!")
    end

    it "raises error when action is not public" do
      expect { subject.handle_action({ "action" => "reject" }.to_json) }.to raise_error(LiteCable::Channel::UnproccessableActionError)
    end

    it "raises error when action doesn't exist" do
      expect { subject.handle_action({ "action" => "foobar" }.to_json) }.to raise_error(LiteCable::Channel::UnproccessableActionError)
    end
  end
end
