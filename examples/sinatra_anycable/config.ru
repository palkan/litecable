# frozen_string_literal: true

lib = File.expand_path("../../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "litecable"
require '../shared/app'

LiteCable.config.log_level = Logger::DEBUG
LiteCable.anycable!

CABLE_URL = "ws://localhost:9293/cable"

run App
