# frozen_string_literal: true

module LiteCable
  # rubocop:disable Metrics/LineLength
  module Channel
    class Error < StandardError; end
    class RejectedError < Error; end
    class UnproccessableActionError < Error; end

    # The channel provides the basic structure of grouping behavior into logical units when communicating over the connection.
    # You can think of a channel like a form of controller, but one that's capable of pushing content to the subscriber in addition to simply
    # responding to the subscriber's direct requests.
    #
    # == Identification
    #
    # Each channel must have a unique identifier, which is used by the connection to resolve the channel's class.
    #
    # Example:
    #
    #  class SecretChannel < LiteCable::Channel::Base
    #    identifier 'my_super_secret_channel'
    #  end
    #
    #  # client-side
    #  App.cable.subscriptions.create('my_super_secret_channel')
    #
    # == Action processing
    #
    # You can declare any public method on the channel (optionally taking a `data` argument),
    # and this method is automatically exposed as callable to the client.
    #
    # Example:
    #
    #   class AppearanceChannel < LiteCable::Channel::Base
    #     def unsubscribed
    #       # here `current_user` is a connection identifier
    #       current_user.disappear
    #     end
    #
    #     def appear(data)
    #       current_user.appear on: data['appearing_on']
    #     end
    #
    #     def away
    #       current_user.away
    #     end
    #   end
    #
    # == Rejecting subscription requests
    #
    # A channel can reject a subscription request in the #subscribed callback by
    # invoking the #reject method:
    #
    #   class ChatChannel < ApplicationCable::Channel
    #     def subscribed
    #       room = Chat::Room[params['room_number']]
    #       reject unless current_user.can_access?(room)
    #     end
    #   end
    #
    # In this example, the subscription will be rejected if the
    # <tt>current_user</tt> does not have access to the chat room. On the
    # client-side, the <tt>Channel#rejected</tt> callback will get invoked when
    # the server rejects the subscription request.
    class Base
      # rubocop:enable Metrics/LineLength
      class << self
        # A set of method names that should be considered actions.
        # This includes all public instance methods on a channel except from Channel::Base methods.
        def action_methods
          @action_methods ||= begin
            # All public instance methods of this class, including ancestors
            methods = (public_instance_methods(true) -
              # Except for public instance methods of Base and its ancestors
              LiteCable::Channel::Base.public_instance_methods(true) +
              # Be sure to include shadowed public instance methods of this class
              public_instance_methods(false)).uniq.map(&:to_s)
            methods.to_set
          end
        end

        attr_reader :id

        # Register the channel by its unique identifier
        # (in order to resolve the channel's class for connections)
        def identifier(id)
          Registry.add(id.to_s, self)
          @id = id
        end
      end

      include Logging
      prepend Streams

      attr_reader :connection, :identifier, :params

      def initialize(connection, identifier, params)
        @connection = connection
        @identifier = identifier
        @params = params.freeze

        delegate_connection_identifiers
      end

      def handle_subscribe
        subscribed if respond_to?(:subscribed)
      end

      def handle_unsubscribe
        unsubscribed if respond_to?(:unsubscribed)
      end

      def handle_action(encoded_message)
        perform_action connection.coder.decode(encoded_message)
      end

      protected

      def reject
        raise RejectedError
      end

      def transmit(data)
        connection.transmit identifier: identifier, message: data
      end

      # Extract the action name from the passed data and process it via the channel.
      def perform_action(data)
        action = extract_action(data)

        raise UnproccessableActionError unless processable_action?(action)
        log(:debug) { log_fmt("Perform action #{action}(#{data})") }
        dispatch_action(action, data)
      end

      def dispatch_action(action, data)
        if method(action).arity == 1
          public_send action, data
        else
          public_send action
        end
      end

      def extract_action(data)
        data.delete("action") || "receive"
      end

      def processable_action?(action)
        self.class.action_methods.include?(action)
      end

      def delegate_connection_identifiers
        connection.identifiers.each do |identifier|
          define_singleton_method(identifier) do
            connection.send(identifier)
          end
        end
      end

      # Add prefix to channel log messages
      def log_fmt(msg)
        "[connection:#{connection.identifier}] [channel:#{self.class.id}] #{msg}"
      end
    end
  end
end
