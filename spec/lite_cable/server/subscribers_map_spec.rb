# frozen_string_literal: true

require "spec_helper"

describe LiteCable::Server::SubscribersMap do
  let(:socket) { spy("socket") }
  let(:socket2) { spy("socket2") }
  let(:coder) { LiteCable::Coders::JSON }

  subject { described_class.new }

  describe "#add_subscriber" do
    it "adds one socket" do
      subject.add_subscriber "test", socket, "channel"
      subject.broadcast "test", "blabla", coder
      expect(socket).to have_received(:transmit).with({identifier: "channel", message: "blabla"}.to_json)
    end

    it "adds several sockets", :aggregate_failures do
      subject.add_subscriber "test", socket, "channel"
      subject.add_subscriber "test", socket2, "channel2"
      subject.add_subscriber "test2", socket, "channel"

      subject.broadcast "test", "blabla", coder
      expect(socket).to have_received(:transmit).with({identifier: "channel", message: "blabla"}.to_json)
      expect(socket2).to have_received(:transmit).with({identifier: "channel2", message: "blabla"}.to_json)

      subject.broadcast "test2", "blublu", coder
      expect(socket).to have_received(:transmit).with({identifier: "channel", message: "blublu"}.to_json)
      expect(socket2).not_to have_received(:transmit).with({identifier: "channel2", message: "blublu"}.to_json)
    end
  end

  describe "#remove_subscriber" do
    before do
      subject.add_subscriber "test", socket, "channel"
      subject.add_subscriber "test2", socket, "channel"
    end

    it "removes socket from stream" do
      subject.remove_subscriber "test", socket, "channel"
      subject.broadcast "test", "blabla", coder
      subject.broadcast "test2", "blublu", coder

      expect(socket).not_to have_received(:transmit).with({identifier: "channel", message: "blabla"}.to_json)
      expect(socket).to have_received(:transmit).with({identifier: "channel", message: "blublu"}.to_json)
    end
  end

  describe "#remove_socket" do
    before do
      subject.add_subscriber "test", socket, "channel"
      subject.add_subscriber "test2", socket, "channel"
      subject.add_subscriber "test3", socket, "channel2"
    end

    it "removes socket from all streams" do
      subject.remove_socket socket, "channel"
      subject.broadcast "test", "blabla", coder
      subject.broadcast "test2", "blublu", coder
      subject.broadcast "test3", "brobro", coder

      expect(socket).not_to have_received(:transmit).with({identifier: "channel", message: "blabla"}.to_json)
      expect(socket).not_to have_received(:transmit).with({identifier: "channel", message: "blublu"}.to_json)
      expect(socket).to have_received(:transmit).with({identifier: "channel2", message: "brobro"}.to_json)
    end
  end
end
