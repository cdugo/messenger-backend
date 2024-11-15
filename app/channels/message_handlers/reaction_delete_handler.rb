module MessageHandlers
  class ReactionDeleteHandler < BaseHandler
    def call
      message = server.messages.find(data['message_id'])
      reaction = message.reactions.find_by(user: current_user, emoji: data['emoji'])
      
      if reaction.nil?
        deliver_error_message(message, "Reaction not found")
        return
      end

      if reaction.destroy
        broadcast_reaction_delete(reaction)
      else
        deliver_error_message(message, "Failed to delete reaction")
      end
    rescue ActiveRecord::RecordNotFound => e
      deliver_error_message(OpenStruct.new(server_id: server.id), "Message not found")
    rescue => e
      deliver_error_message(message || OpenStruct.new(server_id: server.id), 
        "Error deleting reaction: #{e.message}")
    end

    private

    def broadcast_reaction_delete(reaction)
      ActionCable.server.broadcast(
        "server_#{server.id}",
        { 
          type: 'reaction_delete', 
          message_id: reaction.message_id,
          reaction: {
          id: reaction.id,
            username: reaction.user.username
          }
        }
      )
    end
  end
end 