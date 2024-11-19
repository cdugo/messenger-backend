module MessageHandlers
  class MessageCreateHandler < BaseHandler
    def call
      message = Message.create!(
        content: data['content'],
        user: current_user,
        server_id: data['server_id'],
        parent_message_id: data['parent_message_id']
      )

      # Broadcast the message to the message channel
      broadcast_message(message)

      # Broadcast notification using the channel directly
      NotificationChannel.broadcast_to_server(
        message.server_id,
        'new_message',
        {
          message_id: message.id,
          server_id: message.server_id,
          sender: {
            id: message.user.id,
            username: message.user.username
          },
          preview: message.content.truncate(50),
          timestamp: message.created_at
        }
      )

    rescue ActiveRecord::RecordInvalid => e
      error_response(e.message)
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