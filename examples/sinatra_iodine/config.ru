# frozen_string_literal: true

lib = File.expand_path("../../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require '../shared/app'
require "litecable"
require "iodine"

LiteCable.config.log_level = Logger::DEBUG
# Turn Iodine compatibility mode
LiteCable.iodine!

CABLE_URL = "ws://localhost:9293/cable"

run App
