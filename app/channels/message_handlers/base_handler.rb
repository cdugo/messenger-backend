module MessageHandlers
  class BaseHandler
    include ActiveSupport::Rescuable
    
    attr_reader :data, :server, :current_user

    def initialize(data, server, current_user)
      @data = data
      @server = server
      @current_user = current_user
    end

    def call
      raise NotImplementedError
    end

    protected

    def error_response(message)
      broadcast_error('Error', message)
    end

    def deliver_error_message(message, error_text = nil)
      error_message = error_text || 
        (message.respond_to?(:errors) ? message.errors.full_messages.join(', ') : message.to_s)
      broadcast_error('Error', error_message)
    end

    def broadcast_message(message)
      broadcast(
        type: 'message',
        id: message.id,
        content: message.content,
        user_id: message.user_id,
        server_id: message.server_id,
        parent_message_id: message.parent_message_id,
        created_at: message.created_at,
        user: {
          id: message.user.id,
          username: message.user.username
        }
      )
    end

    private

    def broadcast(payload)
      ActionCable.server.broadcast("server_#{server.id}", payload)
    end

    def broadcast_error(error_type, message)
      broadcast(
        type: 'error',
        error_type: error_type,
        message: message,
        timestamp: Time.current
      )
    end

    rescue_from Errors::MessageHandlerError do |e|
      error_response(e.message)
    end
  end
end 