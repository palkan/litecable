# frozen_string_literal: true
require "set"

module LiteCable
  module Connection
    module Identification # :nodoc:
      module ClassMethods # :nodoc:
        # Mark a key as being a connection identifier index
        # that can then be used to find the specific connection again later.
        def identified_by(*identifiers)
          Array(identifiers).each do |identifier|
            attr_writer identifier
            define_method(identifier) do
              return instance_variable_get(:"@#{identifier}") if
                instance_variable_defined?(:"@#{identifier}")
              fetch_identifier(identifier.to_s)
            end
          end

          self.identifiers += identifiers
        end
      end

      def self.prepended(base)
        base.class_eval do
          class << self
            attr_writer :identifiers

            def identifiers
              @identifiers ||= Set.new
            end

            include ClassMethods
          end
        end
      end

      def initialize(socket, identifiers: nil, **hargs)
        @encoded_ids = identifiers ? JSON.parse(identifiers) : {}
        super socket, **hargs
      end

      def identifiers
        self.class.identifiers
      end

      # Return a single connection identifier
      # that combines the value of all the registered identifiers into a single id.
      #
      # You can specify a custom identifier_coder in config
      # to implement specific logic of encoding/decoding
      # custom classes to identifiers.
      #
      # By default uses Raw coder.
      def identifier
        unless defined? @identifier
          values = identifiers_hash.values.compact
          @identifier = values.empty? ? nil : values.map(&:to_s).sort.join(":")
        end

        @identifier
      end

      # Generate identifiers info as hash.
      def identifiers_hash
        identifiers.each_with_object({}) do |id, acc|
          obj = instance_variable_get("@#{id}")
          next unless obj
          acc[id.to_s] = LiteCable.config.identifier_coder.encode(obj)
        end
      end

      def identifiers_json
        identifiers_hash.to_json
      end

      # Fetch identifier and deserialize if neccessary
      def fetch_identifier(name)
        val = @encoded_ids[name]
        val = LiteCable.config.identifier_coder.decode(val) unless val.nil?
        instance_variable_set(
          :"@#{name}",
          val
        )
      end
    end
  end
end
