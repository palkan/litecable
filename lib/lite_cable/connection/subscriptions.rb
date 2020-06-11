# frozen_string_literal: true

module LiteCable
  module Connection
    # Manage the connection channels and route messages
    class Subscriptions
      class Error < StandardError; end
      class AlreadySubscribedError < Error; end
      class UnknownCommandError < Error; end
      class ChannelNotFoundError < Error; end

      include Logging

      def initialize(connection)
        @connection = connection
        @subscriptions = {}
      end

      def identifiers
        subscriptions.keys
      end

      def add(identifier, subscribe = true)
        raise AlreadySubscribedError if find(identifier)

        params = connection.coder.decode(identifier)

        channel_id = params.delete("channel")

        channel_class = Channel::Registry.find!(channel_id)

        subscriptions[identifier] = channel_class.new(connection, identifier, params)
        subscribe ? subscribe_channel(subscriptions[identifier]) : subscriptions[identifier]
      end

      def remove(identifier)
        channel = find!(identifier)
        subscriptions.delete(identifier)
        channel.handle_unsubscribe
        log(:debug) { log_fmt("Unsubscribed from channel #{channel.class.id}") }
        transmit_subscription_cancel(channel.identifier)
      end

      def remove_all
        subscriptions.keys.each(&method(:remove))
      end

      def perform_action(identifier, data)
        channel = find!(identifier)
        channel.handle_action data
      end

      def execute_command(data)
        command = data.delete("command")
        case command
        when "subscribe" then add(data["identifier"])
        when "unsubscribe" then remove(data["identifier"])
        when "message" then perform_action(data["identifier"], data["data"])
        else
          raise UnknownCommandError, "Command not found #{command}"
        end
      end

      def find(identifier)
        subscriptions[identifier]
      end

      def find!(identifier)
        channel = find(identifier)
        raise ChannelNotFoundError unless channel

        channel
      end

      private

      attr_reader :connection, :subscriptions

      def subscribe_channel(channel)
        channel.handle_subscribe
        log(:debug) { log_fmt("Subscribed to channel #{channel.class.id}") }
        transmit_subscription_confirmation(channel.identifier)
        channel
      rescue Channel::RejectedError
        subscriptions.delete(channel.identifier)
        transmit_subscription_rejection(channel.identifier)
        nil
      end

      def transmit_subscription_confirmation(identifier)
        connection.transmit identifier: identifier,
                            type: LiteCable::INTERNAL[:message_types][:confirmation]
      end

      def transmit_subscription_rejection(identifier)
        connection.transmit identifier: identifier,
                            type: LiteCable::INTERNAL[:message_types][:rejection]
      end

      def transmit_subscription_cancel(identifier)
        connection.transmit identifier: identifier,
                            type: LiteCable::INTERNAL[:message_types][:cancel]
      end

      def log_fmt(msg)
        "[connection:#{connection.identifier}] #{msg}"
      end
    end
  end
end
