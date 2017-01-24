# frozen_string_literal: true
require "spec_helper"

class TestBaseConnection < LiteCable::Connection::Base
  attr_reader :connected, :disconnected

  def connect
    @connected = true
  end

  def disconnect
    @disconnected = true
  end
end

describe TestBaseConnection do
  let(:socket_params) { {} }
  let(:socket) { TestSocket.new(socket_params) }

  subject { described_class.new(socket) }

  describe "#handle_connect" do
    it "calls #connect method" do
      subject.handle_connect
      expect(subject.connected).to eq true
    end

    it "sends welcome message" do
      expect { subject.handle_connect }.to change(socket.transmissions, :size).by(1)
      expect(socket.last_transmission).to eq("type" => "welcome")
    end
  end

  describe "#handle_disconnect" do
    it "calls #disconnect method" do
      subject.handle_disconnect
      expect(subject.disconnected).to eq true
      expect(subject).to be_disconnected
    end

    it "calls #unsubscribe_from_all on subscriptions" do
      expect(subject.subscriptions).to receive(:remove_all)
      subject.handle_disconnect
    end
  end

  describe "#close" do
    it "closes socket" do
      subject.close
      expect(socket).to be_closed
    end
  end

  describe "#transmit" do
    context "when disconnected" do
      it "doesn't transmit messages" do
        subject.handle_disconnect
        expect { subject.transmit(data: "I'm alive!") }.not_to change(socket.transmissions, :size)
      end
    end

    context "with non-default coder" do
      subject { described_class.new(socket, coder: LiteCable::Coders::Raw) }

      it "uses specified coder" do
        subject.transmit '{"coder": "raw"}'
        expect(socket.last_transmission).to eq("coder" => "raw")
      end
    end
  end

  describe "#handle_command" do
    it "runs subscriptions #execute_command" do
      expect(subject.subscriptions).to receive(:execute_command).with("command" => "test")
      subject.handle_command('{"command":"test"}')
    end
  end
end
