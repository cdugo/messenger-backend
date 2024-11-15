module MessageHandlers
  class MessageDeleteHandler < BaseHandler
    def call
      message = server.messages.find(data['message_id'])
      return unless message.user_id == current_user.id

      if message.destroy
        broadcast_delete(message.id)
      else
        deliver_error_message(message)
      end
    end

    private

    def broadcast_delete(message_id)
      ActionCable.server.broadcast(
        "server_#{server.id}",
        {
          type: 'message_deleted',
          message_id: message_id
        }
      )
    end
  end
end 