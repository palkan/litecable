# frozen_string_literal: true

module LiteCable # :nodoc:
  # AnyCable extensions
  module AnyCable
    module Broadcasting # :nodoc:
      def broadcast(stream, message, coder: nil)
        coder ||= LiteCable.config.coder
        Anycable.broadcast stream, coder.encode(message)
      end
    end

    module Connection # :nodoc:
      def self.extended(base)
        base.prepend InstanceMethods
      end

      def call(socket, **options)
        new(socket, options)
      end

      # Backward compatibility with AnyCable <= 0.4
      alias create call

      module InstanceMethods # :nodoc:
        def initialize(socket, subscriptions: nil, **hargs)
          super(socket, **hargs)
          # Initialize channels if any
          subscriptions&.each { |id| @subscriptions.add(id, false) }
        end

        def request
          @request ||= Rack::Request.new(socket.env)
        end

        # rubocop: disable Metrics/MethodLength
        def handle_channel_command(identifier, command, data)
          channel = subscriptions.add(identifier, false)
          case command
          when "subscribe"
            !subscriptions.send(:subscribe_channel, channel).nil?
          when "unsubscribe"
            subscriptions.remove(identifier)
            true
          when "message"
            subscriptions.perform_action identifier, data
            true
          else
            false
          end
        rescue LiteCable::Connection::Subscriptions::Error,
               LiteCable::Channel::Error,
               LiteCable::Channel::Registry::Error => e
          log(:error, log_fmt("Connection command failed: #{e}"))
          close
          false
        end
        # rubocop: enable Metrics/MethodLength
      end
    end
  end

  # Patch Lite Cable with AnyCable functionality
  def self.anycable!
    LiteCable::Connection::Base.extend LiteCable::AnyCable::Connection
    LiteCable.singleton_class.prepend LiteCable::AnyCable::Broadcasting
  end
end
