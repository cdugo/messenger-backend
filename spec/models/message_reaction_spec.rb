require 'rails_helper'

RSpec.describe MessageReaction, type: :model do
  let(:user) { create(:user) }
  let(:message) { create(:message) }
  let(:reaction) { build(:message_reaction, user: user, message: message, emoji: '👍') }

  describe 'validations' do
    it { should validate_presence_of(:emoji) }
    
    it 'validates uniqueness of user scoped to message and emoji' do
      create(:message_reaction, user: user, message: message, emoji: '👍')
      duplicate_reaction = build(:message_reaction, user: user, message: message, emoji: '👍')
      expect(duplicate_reaction).not_to be_valid
      expect(duplicate_reaction.errors[:user_id]).to include('has already reacted with this emoji')
    end

    it 'allows same user to react with different emojis' do
      create(:message_reaction, user: user, message: message, emoji: '👍')
      different_emoji = build(:message_reaction, user: user, message: message, emoji: '❤️')
      expect(different_emoji).to be_valid
    end

    it 'allows different users to react with same emoji' do
      create(:message_reaction, user: user, message: message, emoji: '👍')
      other_user = create(:user)
      same_emoji = build(:message_reaction, user: other_user, message: message, emoji: '👍')
      expect(same_emoji).to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:message) }
    it { should belong_to(:user) }
  end

  describe 'callbacks' do
    it 'broadcasts reaction creation' do
      expect {
        reaction.save!
      }.to have_broadcasted_to("server_#{message.server_id}")
        .with(
          a_hash_including(
            type: 'reaction_created',
            message_id: message.id,
            emoji: '👍',
            user: a_hash_including(
              id: user.id,
              username: user.username
            )
          )
        )
    end

    it 'broadcasts reaction deletion' do
      reaction.save!
      expect {
        reaction.destroy
      }.to have_broadcasted_to("server_#{message.server_id}")
        .with(
          a_hash_including(
            type: 'reaction_deleted',
            message_id: message.id,
            emoji: '👍',
            user_id: user.id
          )
        )
    end
  end

  describe 'scopes' do
    let!(:other_message) { create(:message) }
    let!(:other_user) { create(:user) }
    let!(:reaction1) { create(:message_reaction, user: user, message: message, emoji: '👍') }
    let!(:reaction2) { create(:message_reaction, user: other_user, message: message, emoji: '❤️') }
    let!(:reaction3) { create(:message_reaction, user: user, message: other_message, emoji: '😂') }

    describe '.for_message' do
      it 'returns reactions for the specified message' do
        expect(described_class.for_message(message)).to include(reaction1, reaction2)
        expect(described_class.for_message(message)).not_to include(reaction3)
      end
    end

    describe '.by_user' do
      it 'returns reactions by the specified user' do
        expect(described_class.by_user(user)).to include(reaction1, reaction3)
        expect(described_class.by_user(user)).not_to include(reaction2)
      end
    end

    describe '.with_emoji' do
      it 'returns reactions with the specified emoji' do
        expect(described_class.with_emoji('👍')).to include(reaction1)
        expect(described_class.with_emoji('👍')).not_to include(reaction2, reaction3)
      end
    end
  end

  describe 'emoji validation' do
    it 'allows valid emoji' do
      valid_emojis = ['👍', '❤️', '😂', '😮', '😢', '😡']
      valid_emojis.each do |emoji|
        reaction = build(:message_reaction, emoji: emoji)
        expect(reaction).to be_valid
      end
    end

    it 'disallows invalid emoji' do
      invalid_emojis = ['invalid', '', nil, '123']
      invalid_emojis.each do |emoji|
        reaction = build(:message_reaction, emoji: emoji)
        expect(reaction).not_to be_valid
        expect(reaction.errors[:emoji]).to be_present
      end
    end
  end
end 