# frozen_string_literal: true
module LiteCable
  INTERNAL = {
    message_types: {
      welcome: "welcome",
      ping: "ping",
      confirmation: "confirm_subscription",
      rejection: "reject_subscription",
      cancel: "cancel_subscription"
    }.freeze,
    protocols: ["actioncable-v1-json", "actioncable-unsupported"].freeze
  }.freeze
end
