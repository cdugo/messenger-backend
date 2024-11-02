class Server < ApplicationRecord
  has_many :server_members
  has_many :users, through: :server_members
  has_many :messages
end
