# frozen_string_literal: true
require "json"

module LiteCable
  module Coders
    # Wrapper over JSON
    module JSON
      class << self
        def decode(json_str)
          ::JSON.parse(json_str)
        end

        def encode(ruby_obj)
          ruby_obj.to_json
        end
      end
    end
  end
end
