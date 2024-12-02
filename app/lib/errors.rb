module Errors
  class ApplicationError < StandardError; end

  # Authentication errors
  class AuthenticationError < ApplicationError; end

  # Server errors
  class NotServerMemberError < ApplicationError; end
  class ServerOwnershipError < ApplicationError; end

  # WebSocket errors
  class WebSocketError < ApplicationError; end
  class SubscriptionError < WebSocketError; end
  class MessageError < WebSocketError; end
  class MessageHandlerError < WebSocketError; end
end 