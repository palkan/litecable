# frozen_string_literal: true

module LiteCable
  module Server
    module ClientSocket
      class Base # :nodoc:
        include Logging
        include Subscriptions

        attr_reader :active

        def initialize
          @open_handlers = []
          @close_handlers = []
          @message_handlers = []

          @close_on_error = true
        end

        def prevent_close_on_error
          @close_on_error = false
        end

        def transmit(data, _type: :text)
          client&.write data
        rescue => e # rubocop:disable Style/RescueStandardError
          log(:error, "Socket send failed: #{e}")
          close
        end

        def request
          @request ||= Rack::Request.new(client.env)
        end

        def onopen(&block)
          @open_handlers << block
        end

        def on_open(client)
          @client = client
          @active = true
          log(:debug, "WebSocket version #{version}")
          @open_handlers.each(&:call)
        end

        def version
          @version ||= request.get_header('HTTP_SEC_WEBSOCKET_VERSION')
        end

        def onmessage(&block)
          @message_handlers << block
        end

        def onclose(&block)
          @close_handlers << block
        end

        def close
          return unless @active

          @close_handlers.each(&:call)
          close!

          @active = false
        end

        def closed?
          !client.open?
        end

        def on_shutdown(_client)
          close
        end

        def on_close(_client)
          close
        end

        def on_message(_client, data)
          @message_handlers.each do |h|
            begin
              h.call(data)
            rescue => e # rubocop: disable Style/RescueStandardError
              log(:error, "Socket receive failed: #{e}")
              @error_handlers.each { |eh| eh.call(e, data) }
              close if close_on_error
            end
          end
        end

        def cookies
          request.cookies
        end

        private

        attr_reader :client, :close_on_error

        def close!
          client.close
        end
      end
    end
  end
end
