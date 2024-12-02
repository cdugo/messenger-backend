require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { build(:user) }

  describe 'validations' do
    it { should validate_presence_of(:username) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:username) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_length_of(:username).is_at_least(3).is_at_most(30) }
    it { should validate_length_of(:password).is_at_least(6).allow_nil }
  end

  describe 'associations' do
    it { should have_many(:server_members) }
    it { should have_many(:servers).through(:server_members) }
    it { should have_many(:messages) }
  end

  describe 'secure password' do
    it { should have_secure_password }

    it 'saves password as digest' do
      user.password = 'password123'
      user.save
      expect(user.password_digest).not_to eq('password123')
      expect(user.authenticate('password123')).to eq(user)
    end

    it 'is invalid with a blank password on create' do
      user.password = ' ' * 6
      expect(user).not_to be_valid
    end

    it 'allows nil password on update' do
      user.save
      user.password = nil
      expect(user).to be_valid
    end
  end

  describe '#as_json' do
    it 'excludes password_digest' do
      json = user.as_json
      expect(json).not_to include('password_digest')
    end

    it 'includes essential user information' do
      json = user.as_json
      expect(json).to include(
        'id' => user.id,
        'username' => user.username,
        'email' => user.email
      )
    end
  end

  describe 'server membership' do
    let(:server) { create(:server) }

    it 'can join servers' do
      user.save
      expect { user.servers << server }.to change(user.servers, :count).by(1)
    end

    it 'can leave servers' do
      user.save
      user.servers << server
      expect { user.servers.delete(server) }.to change(user.servers, :count).by(-1)
    end

    it 'removes server memberships when user is deleted' do
      user.save
      user.servers << server
      expect { user.destroy }.to change(ServerMember, :count).by(-1)
    end
  end

  describe 'message management' do
    let!(:user) { create(:user) }
    let!(:server) { create(:server) }
    let!(:messages) { create_list(:message, 3, user: user, server: server) }

    it 'has many messages' do
      expect(user.messages.count).to eq(3)
    end

    it 'deletes associated messages when user is deleted' do
      expect { user.destroy }.to change(Message, :count).by(-3)
    end
  end
end 