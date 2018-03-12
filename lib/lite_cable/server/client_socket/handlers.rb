# frozen_string_literal: true

module LiteCable
  module Server
    module ClientSocket
      # Socket event handlers
      module Handlers
        def init_handlers
          @open_handlers     = []
          @message_handlers  = []
          @close_handlers    = []
          @shutdown_handlers = []
          @error_handlers    = []
        end

        # TODO: why not on_open?
        def onopen(&block)
          @open_handlers << block
        end

        def onmessage(&block)
          @message_handlers << block
        end

        def onclose(&block)
          @close_handlers << block
        end

        def onshutdown(&block)
          @shutdown_handlers << block
        end

        def onerror(&block)
          @error_handlers << block
        end
      end
    end
  end
end
