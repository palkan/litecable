# frozen_string_literal: true
# Add missing protocols support to websocket-ruby
module WebSocketExt
  module Protocols # :nodoc:
    module Handshake # :nodoc:
      # Specify server protocols
      def protocols(values)
        @protocols = values
      end

      # Return matching protocol
      def protocol
        return @protocol if instance_variable_defined?(:@protocol)
        protos = @headers['sec-websocket-protocol']

        return @protocol = nil unless protos
        @protocol = begin
          protos = protos.split(/ *, */) if protos.is_a?(String)
          protos.find { |p| @protocols.include?(p) }
        end
      end
    end

    module Handler # :nodoc:
      def handshake_keys
        return super unless @handshake.protocol
        super + [
          [
            'Sec-WebSocket-Protocol',
            @handshake.protocol
          ]
        ]
      end
    end
  end
end

WebSocket::Handshake::Server.include WebSocketExt::Protocols::Handshake
[
  WebSocket::Handshake::Handler::Server04,
  WebSocket::Handshake::Handler::Server75,
  WebSocket::Handshake::Handler::Server76
].each do |handler|
  handler.prepend WebSocketExt::Protocols::Handler
end
