require 'rails_helper'

RSpec.describe MessageChannel, type: :channel do
  let(:user) { create(:user) }
  let(:server) { create(:server) }
  let(:message) { create(:message, server: server, user: user) }

  before do
    stub_connection current_user: user
    server.users << user
    server.create_read_state_for_user(user)
  end

  describe '#subscribed' do
    it 'successfully subscribes to server channel when authorized' do
      subscribe(server_id: server.id)
      
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("server_#{server.id}")
    end

    it 'rejects subscription when server not found' do
      subscribe(server_id: 0)
      
      expect(subscription).to be_rejected
      expect(subscription.streams).to be_empty
    end

    it 'rejects subscription when user not member of server' do
      other_server = create(:server)
      subscribe(server_id: other_server.id)
      
      expect(subscription).to be_rejected
      expect(subscription.streams).to be_empty
    end

    it 'marks messages as read upon subscription' do
      read_state = server.server_read_states.find_by(user: user)
      read_state.update(unread_count: 5)
      
      subscribe(server_id: server.id)
      
      read_state.reload
      expect(read_state.unread_count).to eq(0)
    end

    it 'transmits confirmation message' do
      subscribe(server_id: server.id)
      
      expect(transmissions.last).to eq({
        'type' => 'confirm_subscription',
        'server_id' => server.id
      })
    end
  end

  describe '#unsubscribed' do
    it 'stops all streams' do
      subscribe(server_id: server.id)
      
      expect(subscription).to receive(:stop_all_streams)
      unsubscribe
    end
  end

  describe '#message_create' do
    before { subscribe(server_id: server.id) }

    it 'creates and broadcasts new message' do
      expect {
        perform :message_create, {
          'content' => 'Hello World',
          'server_id' => server.id
        }
      }.to have_broadcasted_to("server_#{server.id}")
        .with(
          a_hash_including(
            'type' => 'message',
            'content' => 'Hello World',
            'user' => a_hash_including('id' => user.id)
          )
        )
    end

    it 'handles message with attachments' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('test image'),
        filename: 'test.jpg',
        content_type: 'image/jpeg'
      )

      expect {
        perform :message_create, {
          'content' => 'With attachment',
          'server_id' => server.id,
          'attachment_ids' => [blob.signed_id]
        }
      }.to have_broadcasted_to("server_#{server.id}")
        .with(
          a_hash_including(
            'type' => 'message',
            'content' => 'With attachment',
            'attachments' => array_including(
              a_hash_including('filename' => 'test.jpg')
            )
          )
        )
    end

    it 'handles replies to messages' do
      parent_message = create(:message, server: server)
      
      expect {
        perform :message_create, {
          'content' => 'Reply message',
          'server_id' => server.id,
          'parent_message_id' => parent_message.id
        }
      }.to have_broadcasted_to("server_#{server.id}")
        .with(
          a_hash_including(
            'type' => 'message',
            'content' => 'Reply message',
            'parent_message_id' => parent_message.id
          )
        )
    end

    it 'broadcasts error for invalid messages' do
      expect {
        perform :message_create, {
          'content' => '',
          'server_id' => server.id
        }
      }.to have_broadcasted_to("server_#{server.id}")
        .with(
          a_hash_including(
            'type' => 'error'
          )
        )
    end

    it 'updates read state on message creation' do
      read_state = server.server_read_states.find_by(user: user)
      old_timestamp = read_state.last_read_at
      
      perform :message_create, {
        'content' => 'New message',
        'server_id' => server.id
      }
      
      read_state.reload
      expect(read_state.last_read_at).to be > old_timestamp
    end
  end

  describe '#message_delete' do
    before { subscribe(server_id: server.id) }

    it 'deletes and broadcasts message deletion' do
      message = create(:message, user: user, server: server)
      
      expect {
        perform :message_delete, {
          'message_id' => message.id,
          'server_id' => server.id
        }
      }.to have_broadcasted_to("server_#{server.id}")
        .with(
          a_hash_including(
            'type' => 'message_deleted',
            'message_id' => message.id
          )
        )
    end

    it 'prevents deletion of messages by other users' do
      other_user_message = create(:message, server: server)
      
      expect {
        perform :message_delete, {
          'message_id' => other_user_message.id,
          'server_id' => server.id
        }
      }.not_to have_broadcasted_to("server_#{server.id}")
        .with(a_hash_including('type' => 'message_deleted'))
    end
  end

  describe '#reaction_create' do
    before { subscribe(server_id: server.id) }

    it 'creates and broadcasts new reaction' do
      message = create(:message, server: server)
      
      expect {
        perform :reaction_create, {
          'message_id' => message.id,
          'server_id' => server.id,
          'emoji' => '👍'
        }
      }.to have_broadcasted_to("server_#{server.id}")
        .with(
          a_hash_including(
            'type' => 'reaction_created',
            'message_id' => message.id,
            'emoji' => '👍'
          )
        )
    end

    it 'prevents duplicate reactions' do
      message = create(:message, server: server)
      create(:message_reaction, message: message, user: user, emoji: '👍')
      
      expect {
        perform :reaction_create, {
          'message_id' => message.id,
          'server_id' => server.id,
          'emoji' => '👍'
        }
      }.to have_broadcasted_to("server_#{server.id}")
        .with(
          a_hash_including(
            'type' => 'error'
          )
        )
    end
  end

  describe '#reaction_delete' do
    before { subscribe(server_id: server.id) }

    it 'deletes and broadcasts reaction deletion' do
      message = create(:message, server: server)
      reaction = create(:message_reaction, message: message, user: user, emoji: '👍')
      
      expect {
        perform :reaction_delete, {
          'message_id' => message.id,
          'server_id' => server.id,
          'emoji' => '👍'
        }
      }.to have_broadcasted_to("server_#{server.id}")
        .with(
          a_hash_including(
            'type' => 'reaction_deleted',
            'message_id' => message.id,
            'emoji' => '👍'
          )
        )
    end

    it 'prevents deletion of reactions by other users' do
      message = create(:message, server: server)
      other_user = create(:user)
      reaction = create(:message_reaction, message: message, user: other_user, emoji: '👍')
      
      expect {
        perform :reaction_delete, {
          'message_id' => message.id,
          'server_id' => server.id,
          'emoji' => '👍'
        }
      }.not_to have_broadcasted_to("server_#{server.id}")
        .with(a_hash_including('type' => 'reaction_deleted'))
    end
  end

  describe 'error handling' do
    before { subscribe(server_id: server.id) }

    it 'handles invalid JSON' do
      expect {
        perform :message_create, 'invalid json'
      }.to have_broadcasted_to("server_#{server.id}")
        .with(
          a_hash_including(
            'type' => 'error',
            'message' => include('Invalid message format')
          )
        )
    end

    it 'handles unauthorized server access' do
      other_server = create(:server)
      
      expect {
        perform :message_create, {
          'content' => 'Hello',
          'server_id' => other_server.id
        }
      }.to have_broadcasted_to("server_#{server.id}")
        .with(
          a_hash_including(
            'type' => 'error',
            'message' => include('User not authorized for this server')
          )
        )
    end
  end
end 