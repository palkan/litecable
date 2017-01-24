# frozen_string_literal: true
# Test connection with `user` identifier
class TestConnection < LiteCable::Connection::Base
  identified_by :user
end
