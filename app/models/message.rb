class Message < ApplicationRecord
  include Rails.application.routes.url_helpers
  
  belongs_to :user
  belongs_to :server
  belongs_to :parent_message, class_name: 'Message', optional: true
  has_many :replies, class_name: 'Message', foreign_key: 'parent_message_id', dependent: :destroy
  has_many :reactions, class_name: 'MessageReaction', dependent: :destroy
  has_many_attached :attachments do |attachable|
    attachable.variant :thumb, resize_to_limit: [100, 100]
  end

  validates :user_id, presence: true
  validates :server_id, presence: true
  
  validate :parent_message_in_same_server
  validate :attachments_limit
  validate :acceptable_attachments
  validate :content_or_attachments_present

  after_commit :increment_unread_counts, on: :create

  def attachment_urls
    return [] unless attachments.attached?

    host_options = { host: 'localhost:8080' }
    
    attachments.map do |attachment|
      {
        id: attachment.id,
        url: rails_blob_url(attachment, host_options),
        thumbnail_url: attachment.representable? ? 
          rails_representation_url(attachment.representation(:thumb), host_options) : nil
      }
    end
  end

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

  def attachments_limit
    return unless attachments.attached?
    errors.add(:attachments, "too many files") if attachments.count > 10
  end

  def acceptable_attachments
    return unless attachments.attached?

    attachments.each do |attachment|
      unless attachment.byte_size <= 10.megabytes
        errors.add(:attachments, "file too large")
      end

      acceptable_types = ["image/jpeg", "image/png", "image/gif", "video/mp4", "video/quicktime"]
      unless acceptable_types.include?(attachment.content_type)
        errors.add(:attachments, "must be an image or video file")
      end
    end
  end

  def content_or_attachments_present
    if content.blank? && !attachments.attached?
      errors.add(:base, "Message must have content or attachments")
    end
  end
end
