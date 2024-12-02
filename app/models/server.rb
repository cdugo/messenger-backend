class Server < ApplicationRecord
  has_many :server_members, dependent: :destroy
  has_many :users, through: :server_members
  has_many :messages, dependent: :destroy
  has_many :server_read_states, dependent: :destroy

  after_commit :create_read_state_for_owner, on: :create

  def create_read_state_for_user(user)
    return if server_read_states.exists?(user: user)
    
    server_read_states.create!(
      user: user,
      last_read_at: Time.current,
      unread_count: 0
    )
  end

  private

  def create_read_state_for_owner
    owner = User.find_by(id: owner_id)
    create_read_state_for_user(owner) if owner
  end
end
