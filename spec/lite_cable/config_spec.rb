# frozen_string_literal: true

require "spec_helper"

describe LiteCable::Config do
  let(:config) { LiteCable.config }

  it "sets defailts", :aggregate_failures do
    expect(config.coder).to eq LiteCable::Coders::JSON
    expect(config.identifier_coder).to eq LiteCable::Coders::Raw
  end
end
