module MessageHandlers
  class BaseHandler
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

    def deliver_error_message(message, error_text = nil)
      broadcast(
        type: 'error',
        message: error_text || message.errors.full_messages.join(', ')
      )
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
  end
end 