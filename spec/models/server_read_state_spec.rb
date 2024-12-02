require 'rails_helper'

RSpec.describe ServerReadState, type: :model do
  let(:user) { create(:user) }
  let(:server) { create(:server) }
  let(:read_state) { create(:server_read_state, user: user, server: server) }

  describe 'validations' do
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:server) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:server_id) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:server) }
  end

  describe '#mark_as_read!' do
    before do
      read_state.update(unread_count: 5)
    end

    it 'resets unread count to zero' do
      read_state.mark_as_read!
      expect(read_state.reload.unread_count).to eq(0)
    end

    it 'updates last_read_at timestamp' do
      old_timestamp = read_state.last_read_at
      read_state.mark_as_read!
      expect(read_state.reload.last_read_at).to be > old_timestamp
    end
  end

  describe '#mark_as_unread!' do
    before do
      read_state.update(unread_count: 0)
    end

    it 'increments unread count' do
      read_state.mark_as_unread!
      expect(read_state.reload.unread_count).to eq(1)
    end

    it 'does not update last_read_at timestamp' do
      old_timestamp = read_state.last_read_at
      read_state.mark_as_unread!
      expect(read_state.reload.last_read_at).to eq(old_timestamp)
    end
  end

  describe '#unread_messages?' do
    it 'returns true when unread_count is positive' do
      read_state.update(unread_count: 1)
      expect(read_state.unread_messages?).to be true
    end

    it 'returns false when unread_count is zero' do
      read_state.update(unread_count: 0)
      expect(read_state.unread_messages?).to be false
    end
  end

  describe 'scopes' do
    let!(:other_user) { create(:user) }
    let!(:other_server) { create(:server) }
    let!(:other_read_state) { create(:server_read_state, user: other_user, server: other_server) }

    describe '.for_user' do
      it 'returns read states for the specified user' do
        expect(described_class.for_user(user)).to include(read_state)
        expect(described_class.for_user(user)).not_to include(other_read_state)
      end
    end

    describe '.for_server' do
      it 'returns read states for the specified server' do
        expect(described_class.for_server(server)).to include(read_state)
        expect(described_class.for_server(server)).not_to include(other_read_state)
      end
    end

    describe '.with_unread_messages' do
      before do
        read_state.update(unread_count: 1)
        other_read_state.update(unread_count: 0)
      end

      it 'returns only read states with unread messages' do
        expect(described_class.with_unread_messages).to include(read_state)
        expect(described_class.with_unread_messages).not_to include(other_read_state)
      end
    end
  end

  describe 'callbacks' do
    it 'initializes unread_count to zero on creation' do
      new_read_state = build(:server_read_state, user: user, server: server)
      expect(new_read_state.unread_count).to be_nil
      new_read_state.save!
      expect(new_read_state.reload.unread_count).to eq(0)
    end

    it 'sets last_read_at on creation' do
      new_read_state = build(:server_read_state, user: user, server: server)
      expect(new_read_state.last_read_at).to be_nil
      new_read_state.save!
      expect(new_read_state.reload.last_read_at).to be_present
    end
  end
end 