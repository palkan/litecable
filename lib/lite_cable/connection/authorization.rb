# frozen_string_literal: true

module LiteCable
  module Connection
    class UnauthorizedError < StandardError; end

    # Include methods to control authorization flow
    module Authorization
      def reject_unauthorized_connection
        raise UnauthorizedError
      end
    end
  end
end
