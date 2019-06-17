# frozen_string_literal: true

module LiteCable
  module Server
    module ClientSocket
      # Wrapper over web socket
      class Base
        include Logging
        include Subscriptions

        attr_reader :version, :active

        def initialize(env, socket, version)
          log(:debug, "WebSocket version #{version}")
          @env = env
          @socket = socket
          @version = version
          @active = true

          @open_handlers    = []
          @message_handlers = []
          @close_handlers   = []
          @error_handlers   = []

          @close_on_error = true
        end

        def prevent_close_on_error
          @close_on_error = false
        end

        def transmit(data, type: :text)
          frame = WebSocket::Frame::Outgoing::Server.new(
            version: version,
            data: data,
            type: type
          )
          socket.write frame.to_s
        rescue IOError, Errno::EPIPE, Errno::ETIMEDOUT => e
          log(:error, "Socket send failed: #{e}")
          close
        end

        def request
          @request ||= Rack::Request.new(@env)
        end

        def onopen(&block)
          @open_handlers << block
        end

        def onmessage(&block)
          @message_handlers << block
        end

        def onclose(&block)
          @close_handlers << block
        end

        def onerror(&block)
          @error_handlers << block
        end

        # rubocop: disable Metrics/MethodLength
        def listen
          keepalive
          Thread.new do
            Thread.current.abort_on_exception = true
            begin
              @open_handlers.each(&:call)
              each_frame do |data|
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
            ensure
              close
            end
          end
        end
        # rubocop: enable Metrics/MethodLength

        def close
          return unless @active

          @close_handlers.each(&:call)
          close!

          @active = false
        end

        def closed?
          @socket.closed?
        end

        private

        attr_reader :socket, :close_on_error

        def close!
          if @socket.respond_to?(:closed?)
            close_socket unless @socket.closed?
          else
            close_socket
          end
        end

        def close_socket
          frame = WebSocket::Frame::Outgoing::Server.new(version: version, type: :close, code: 1000)
          @socket.write(frame.to_s) if frame.supported?
          @socket.close
        rescue IOError, Errno::EPIPE, Errno::ETIMEDOUT # rubocop:disable Lint/HandleExceptions
          # already closed
        end

        def keepalive
          thread = Thread.new do
            Thread.current.abort_on_exception = true
            loop do
              sleep 5
              transmit nil, type: :ping
            end
          end

          onclose do
            thread.kill
          end
        end

        def each_frame
          framebuffer = WebSocket::Frame::Incoming::Server.new(version: version)

          while IO.select([socket])
            data = socket.respond_to?(:recv) ? socket.recv(2000) : socket.readpartial(2000)
            break if data.empty?

            framebuffer << data
            while frame = framebuffer.next # rubocop:disable Lint/AssignmentInCondition
              case frame.type
              when :close
                return
              when :text, :binary
                yield frame.data
              end
            end
          end
        rescue Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Errno::ECONNRESET, IOError, Errno::EBADF => e
          log(:debug, "Socket frame error: #{e}")
          nil # client disconnected or timed out
        end
      end
    end
  end
end
