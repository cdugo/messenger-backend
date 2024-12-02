class ServerReadState < ApplicationRecord
  belongs_to :user
  belongs_to :server

  validates :user_id, uniqueness: { scope: :server_id }

  scope :for_user, ->(user) { where(user: user) }
  scope :for_server, ->(server) { where(server: server) }
  scope :with_unread_messages, -> { where('unread_count > 0') }

  before_create :set_defaults

  def mark_as_read!
    update!(unread_count: 0, last_read_at: Time.current)
  end

  def mark_as_unread!
    increment!(:unread_count)
  end

  def unread_messages?
    unread_count.to_i > 0
  end

  private

  def set_defaults
    self.unread_count ||= 0
    self.last_read_at ||= Time.current
  end
end 