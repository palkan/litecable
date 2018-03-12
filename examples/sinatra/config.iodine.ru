#!/usr/bin/env ruby
# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path("../../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "./chat"
require "rack"

LiteCable.config.log_level = Logger::DEBUG

# Turn Iodine compatibility mode
LiteCable.iodine!
# LiteCable::Iodine.connection_factory = Chat::Connection

# FIXME nil, серьезно?
run LiteCable::Iodine::RackApp.new(nil, connection_class: Chat::Connection)
