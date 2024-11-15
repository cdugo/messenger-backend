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

  private

  def parent_message_in_same_server
    if parent_message_id.present? && parent_message&.server_id != server_id
      errors.add(:parent_message_id, "must belong to the same server")
    end
  end
end
