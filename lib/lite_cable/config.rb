# frozen_string_literal: true

require "anyway"
require 'logger'

module LiteCable
  # Anycable configuration
  class Config < Anyway::Config
    require "lite_cable/coders/json"
    require "lite_cable/coders/raw"

    config_name :litecable

    attr_config :logger,
                coder: Coders::JSON,
                identifier_coder: Coders::Raw,
                log_level: Logger::INFO
  end
end
