class Message < ApplicationRecord
  include Rails.application.routes.url_helpers
  include UrlOptions
  
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
  
  validate :validate_parent_message
  validate :validate_attachments
  validate :content_or_attachments_present

  after_commit :increment_unread_counts, on: :create

  def attachment_urls
    return [] unless attachments.attached?
    
    attachments.map do |attachment|
      {
        id: attachment.id,
        url: rails_blob_url(attachment, default_url_options),
        thumbnail_url: attachment.representable? ? 
          rails_representation_url(attachment.representation(:thumb), default_url_options) : nil
      }
    end
  end

  private

  def validate_parent_message
    if parent_message_id.present?
      unless server.messages.exists?(parent_message_id)
        errors.add(:parent_message_id, "must belong to the same server")
      end
    end
  end

  def validate_attachments
    return unless attachments.attached?

    attachments.each do |attachment|
      unless attachment.content_type.in?(%w[image/jpeg image/png image/gif video/mp4 video/quicktime])
        errors.add(:attachments, "must be an image or video file")
      end
      
      if attachment.byte_size > 10.megabytes
        errors.add(:attachments, "must be less than 10MB")
      end
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

  def content_or_attachments_present
    if content.blank? && !attachments.attached?
      errors.add(:base, "Message must have content or attachments")
    end
  end
end
