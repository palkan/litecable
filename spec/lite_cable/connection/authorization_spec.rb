# frozen_string_literal: true

require "spec_helper"

class TestAuthorizationConnection < LiteCable::Connection::Base
  attr_reader :connected

  def connect
    reject_unauthorized_connection unless cookies["user"]
    @connected = true
  end
end

describe TestAuthorizationConnection do
  let(:cookies) { "" }
  let(:socket_params) { {env: {"HTTP_COOKIE" => cookies}} }
  let(:socket) { TestSocket.new(**socket_params) }

  subject { described_class.new(socket) }

  describe "#handle_open" do
    it "raises exception if rejected" do
      expect(subject).to receive(:close)
      expect { subject.handle_open }.not_to change(socket.transmissions, :size)
    end

    context "when accepted" do
      let(:cookies) { "user=john;" }

      it "succesfully connects" do
        subject.handle_open
        expect(subject.connected).to eq true
      end
    end
  end
end
