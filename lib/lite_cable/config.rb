# frozen_string_literal: true

require "anyway_config"
require "logger"

module LiteCable
  # AnyCable configuration
  class Config < Anyway::Config
    require "lite_cable/coders/json"
    require "lite_cable/coders/raw"

    config_name :litecable

    attr_config :logger,
      coder: Coders::JSON,
      broadcast_adapter: defined?(::AnyCable::VERSION) ? :any_cable : :memory,
      identifier_coder: Coders::Raw,
      log_level: Logger::INFO
  end
end
