# frozen_string_literal: true
require "anyway"

module LiteCable
  # Anycable configuration
  class Config < Anyway::Config
    require "lite_cable/coders/json"
    require "lite_cable/coders/raw"

    config_name :lite_cable

    attr_config coder: Coders::JSON,
                identifier_coder: Coders::Raw
  end
end
