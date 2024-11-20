class Server < ApplicationRecord
  has_many :server_members, dependent: :destroy
  has_many :users, through: :server_members
  has_many :messages, dependent: :destroy
  has_many :server_read_states, dependent: :destroy

  after_commit :create_read_state_for_owner, on: :create

  def create_read_state_for_user(user)
    server_read_states.create!(
      user: user,
      last_read_at: Time.current,
      unread_count: 0
    )
  end

  private

  def create_read_state_for_owner
    create_read_state_for_user(users.first) # owner is always the first user
  end
end
