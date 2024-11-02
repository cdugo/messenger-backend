class User < ApplicationRecord
  has_many :server_members
  has_many :servers, through: :server_members
  has_many :messages
end
