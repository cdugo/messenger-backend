module MessageHandlers
  class ReactionCreateHandler < BaseHandler
    def call
      
      message = server.messages.find(data['message_id'])
      
      reaction = message.reactions.create!(
        user: current_user, 
        emoji: data['emoji']
      )
      
      broadcast_reaction(reaction)
    rescue ActiveRecord::RecordInvalid => e
      puts "❌ Validation error: #{e.record.errors.full_messages}"
      deliver_error_message(message, e.record.errors.full_messages.join(', '))
    rescue => e
      puts "❌ General error: #{e.message}"
      puts e.backtrace.join("\n")
      deliver_error_message(message, "Error creating reaction: #{e.message}")
    end

    private

    def broadcast_reaction(reaction)
      payload = {
        type: 'reaction',
        message_id: reaction.message_id,
        reaction: {
          id: reaction.id,
          emoji: reaction.emoji,
          username: reaction.user.username
        }
      }
      
      ActionCable.server.broadcast("server_#{server.id}", payload)
    end
  end
end 