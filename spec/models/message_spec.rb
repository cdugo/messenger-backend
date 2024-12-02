require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:user) { create(:user) }
  let(:server) { create(:server) }
  let(:message) { build(:message, user: user, server: server) }

  describe 'validations' do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:server_id) }
    
    context 'content and attachments' do
      it 'is valid with content but no attachments' do
        message.content = 'Hello'
        expect(message).to be_valid
      end

      it 'is valid with attachments but no content' do
        message.content = ''
        message.attachments.attach(
          io: StringIO.new('test image'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )
        expect(message).to be_valid
      end

      it 'is invalid without both content and attachments' do
        message.content = ''
        expect(message).not_to be_valid
        expect(message.errors[:base]).to include('Message must have content or attachments')
      end
    end

    context 'attachments validation' do
      it 'validates attachment count' do
        11.times do
          message.attachments.attach(
            io: StringIO.new('test image'),
            filename: 'test.jpg',
            content_type: 'image/jpeg'
          )
        end
        expect(message).not_to be_valid
        expect(message.errors[:attachments]).to include('too many files')
      end

      it 'validates attachment size' do
        allow_any_instance_of(ActiveStorage::Blob).to receive(:byte_size).and_return(11.megabytes)
        message.attachments.attach(
          io: StringIO.new('test image'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )
        expect(message).not_to be_valid
        expect(message.errors[:attachments]).to include('file too large')
      end

      it 'validates attachment content type' do
        message.attachments.attach(
          io: StringIO.new('test file'),
          filename: 'test.txt',
          content_type: 'text/plain'
        )
        expect(message).not_to be_valid
        expect(message.errors[:attachments]).to include('must be an image or video file')
      end
    end

    context 'parent message validation' do
      let(:parent_message) { create(:message, server: server) }

      it 'allows messages without parent' do
        message.parent_message = nil
        expect(message).to be_valid
      end

      it 'allows messages with parent in same server' do
        message.parent_message = parent_message
        expect(message).to be_valid
      end

      it 'disallows messages with parent in different server' do
        different_server = create(:server)
        different_parent = create(:message, server: different_server)
        message.parent_message = different_parent
        expect(message).not_to be_valid
        expect(message.errors[:parent_message_id]).to include('must belong to the same server')
      end
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:server) }
    it { should belong_to(:parent_message).optional }
    it { should have_many(:replies).dependent(:destroy) }
    it { should have_many(:reactions).dependent(:destroy) }
    it { should have_many_attached(:attachments) }
  end

  describe 'callbacks' do
    let(:server_member) { create(:user) }
    
    before do
      server.users << server_member
      server.reload
      server.create_read_state_for_user(server_member)
    end

    it 'increments unread count for non-subscribed users' do
      read_state = server.server_read_states.find_by(user: server_member)
      initial_count = read_state.unread_count
      
      # Simulate user not being subscribed
      allow(ActionCable.server).to receive(:connections).and_return([])
      
      message.save!
      
      read_state.reload
      expect(read_state.unread_count).to eq(initial_count + 1)
    end

    it 'updates last_read_at for subscribed users' do
      read_state = server.server_read_states.find_by(user: server_member)
      old_timestamp = read_state.last_read_at
      
      # Simulate user being subscribed
      allow(ActionCable.server).to receive(:connections)
        .and_return([OpenStruct.new(current_user: server_member)])
      
      message.save!
      
      read_state.reload
      expect(read_state.last_read_at).to be > old_timestamp
    end

    it 'broadcasts to message channel after creation' do
      expect {
        message.save!
      }.to have_broadcasted_to("server_#{message.server_id}")
    end
  end

  describe '#attachment_urls' do
    it 'returns empty array when no attachments' do
      expect(message.attachment_urls).to eq([])
    end

    it 'returns array of attachment urls when attachments present' do
      message.attachments.attach(
        io: StringIO.new('test image'),
        filename: 'test.jpg',
        content_type: 'image/jpeg'
      )
      
      urls = message.attachment_urls
      expect(urls).to be_an(Array)
      expect(urls.first).to include(
        'id' => kind_of(Integer),
        'url' => match(/rails\/active_storage\/blobs/),
        'thumbnail_url' => match(/rails\/active_storage\/representations/)
      )
    end
  end
end 