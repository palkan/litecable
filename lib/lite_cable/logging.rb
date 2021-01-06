# frozen_string_literal: true

require "logger"

module LiteCable
  module Logging # :nodoc:
    PREFIX = "LiteCable"

    class << self
      def logger
        return @logger if instance_variable_defined?(:@logger)

        @logger = LiteCable.config.logger
        return if @logger == false

        @logger ||= ::Logger.new($stderr).tap do |logger|
          logger.level = LiteCable.config.log_level
        end
      end
    end

    private

    def log(level, message = nil)
      return unless LiteCable::Logging.logger

      LiteCable::Logging.logger.send(level, PREFIX) { message || yield }
    end
  end
end
