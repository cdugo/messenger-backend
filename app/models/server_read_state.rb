class ServerReadState < ApplicationRecord
  belongs_to :user
  belongs_to :server

  def mark_as_read!
    update!(
      last_read_at: Time.current,
      unread_count: 0
    )
  end

  def mark_as_unread!
    increment!(:unread_count)
  end

  def touch_last_read!
    touch(:last_read_at)
  end
end 