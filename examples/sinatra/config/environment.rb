# frozen_string_literal: true

lib = File.expand_path("../../../lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative "../app"
require_relative "../chat"

LiteCable.config.log_level = Logger::DEBUG

AnyCable.connection_factory = Chat::Connection
