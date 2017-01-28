# frozen_string_literal: true
require "spec_helper"

class TestIdentificationConnection < LiteCable::Connection::Base
  identified_by :user, :john

  def connect
    @user = cookies["user"]
    @john = @user == "john"
  end
end

class CustomIdCoder
  class << self
    def encode(val)
      if val.is_a?(String)
        val.reverse
      else
        val
      end
    end

    alias decode encode
  end
end

describe TestIdentificationConnection do
  let(:cookies) { "user=john;" }
  let(:socket_params) { { env: { "HTTP_COOKIE" => cookies } } }
  let(:socket) { TestSocket.new(socket_params) }

  subject do
    described_class.new(socket).tap(&:handle_open)
  end

  it "create accessors" do
    expect(subject.user).to eq "john"
    expect(subject.john).to eq true
  end

  describe "#identifier" do
    it "returns string identifier" do
      expect(subject.identifier).to eq("john:true")
    end

    context "when some identifiers are nil" do
      let(:cookies) { "user=jack" }

      it "returns string identifier" do
        expect(subject.identifier).to eq("jack")
      end
    end

    context "when all identifiers are nil" do
      let(:cookies) { "" }

      it "returns string identifier" do
        expect(subject.identifier).to be_nil
      end
    end

    context "with custom identifier coder" do
      prepend_before { allow(LiteCable.config).to receive(:identifier_coder).and_return(CustomIdCoder) }

      it "uses custom id coder" do
        expect(subject.identifier).to eq("nhoj:true")
      end
    end
  end

  describe "#identifiers_hash" do
    it "returns a hash" do
      expect(subject.identifiers_hash).to eq("user" => "john", "john" => true)
    end
  end

  context "with encoded_identifiers" do
    prepend_before { allow(LiteCable.config).to receive(:identifier_coder).and_return(CustomIdCoder) }

    let(:identifiers) { { "user" => "kcaj", "john" => false }.to_json }

    subject { described_class.new(socket, identifiers: identifiers) }

    it "deserialize values from provided hash" do
      expect(subject.user).to eq "jack"
      expect(subject.john).to eq false
    end

    it "calls decoded only once" do
      expect(CustomIdCoder).to receive(:decode).once
      subject.user
      subject.user
    end
  end
end
