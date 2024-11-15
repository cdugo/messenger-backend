module MessageHandlers
  class MessageUpdateHandler < BaseHandler
    def call
      message = server.messages.find(data['message_id'])
      return unless message.user_id == current_user.id

      if message.update(content: data['content'])
        broadcast_message(message)
      else
        deliver_error_message(message)
      end
    end

    private

    def broadcast_message(message)
      ActionCable.server.broadcast(
        "server_#{message.server_id}",
        {
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
        }
      )
    end
  end
end 