class User < ApplicationRecord
  has_many :server_members, dependent: :destroy
  has_many :servers, through: :server_members
  has_many :messages, dependent: :destroy
  has_many :server_read_states, dependent: :destroy
  has_many :message_reactions, dependent: :destroy

  has_secure_password

  validates :username, presence: true, uniqueness: true, length: { in: 3..30 }
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 6 }, allow_nil: true

  def as_json(options = {})
    super(options.merge(except: [:password_digest]))
  end
end
