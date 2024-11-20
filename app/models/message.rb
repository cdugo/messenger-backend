class Message < ApplicationRecord
  belongs_to :user
  belongs_to :server
  belongs_to :parent_message, class_name: 'Message', optional: true
  has_many :replies, class_name: 'Message', foreign_key: 'parent_message_id', dependent: :destroy
  has_many :reactions, class_name: 'MessageReaction', dependent: :destroy

  validates :content, presence: true
  validates :user_id, presence: true
  validates :server_id, presence: true
  
  validate :parent_message_in_same_server

  after_commit :increment_unread_counts, on: :create

  private

  def parent_message_in_same_server
    if parent_message_id.present? && parent_message&.server_id != server_id
      errors.add(:parent_message_id, "must belong to the same server")
    end
  end

  def increment_unread_counts
    # Get all read states for users in this server except the message sender
    read_states = server.server_read_states.where.not(user_id: user_id)

    # Get subscribed user IDs from MessageChannel
    subscribed_user_ids = ActionCable.server.connections.map(&:current_user).compact.map(&:id)

    # Only increment unread count for users not currently subscribed
    read_states.each do |read_state|
      if subscribed_user_ids.include?(read_state.user_id)
        # Just update last_read_at for subscribed users
        read_state.touch(:last_read_at)
      else
        # Increment unread count for non-subscribed users
        read_state.mark_as_unread!
      end
    end
  end
end
