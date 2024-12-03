class MessageReaction < ApplicationRecord
  belongs_to :message
  belongs_to :user

  validates :emoji, presence: true


  scope :for_message, ->(message) { where(message: message) }
  scope :by_user, ->(user) { where(user: user) }
  scope :with_emoji, ->(emoji) { where(emoji: emoji) }

  after_create_commit :broadcast_creation
  after_destroy_commit :broadcast_deletion

  private

  def broadcast_creation
    ActionCable.server.broadcast(
      "server_#{message.server_id}",
      {
        type: 'reaction_created',
        message_id: message_id,
        emoji: emoji,
        user: {
          id: user.id,
          username: user.username
        }
      }
    )
  end

  def broadcast_deletion
    ActionCable.server.broadcast(
      "server_#{message.server_id}",
      {
        type: 'reaction_deleted',
        message_id: message_id,
        emoji: emoji,
        user_id: user_id
      }
    )
  end
end