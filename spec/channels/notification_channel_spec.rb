require 'rails_helper'

RSpec.describe NotificationChannel, type: :channel do
  let(:user) { create(:user) }
  let(:server) { create(:server) }

  before do
    stub_connection current_user: user
  end

  describe '#subscribed' do
    it 'successfully subscribes to notification channel' do
      subscribe
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_from("notifications:user:#{user.id}")
    end

    it 'rejects subscription for unauthenticated users' do
      stub_connection current_user: nil
      subscribe
      expect(subscription).to be_rejected
    end
  end

  describe '#unsubscribed' do
    before { subscribe }

    it 'stops all streams' do
      expect(subscription).to receive(:stop_all_streams)
      unsubscribe
    end
  end

  describe '.broadcast_to_server' do
    let(:other_user) { create(:user) }
    let(:message) { create(:message, server: server, user: user) }

    before do
      server.users << [user, other_user]
    end

    it 'broadcasts new message notifications to all server members' do
      notification_data = {
        message_id: message.id,
        server_id: server.id,
        sender: {
          id: user.id,
          username: user.username
        },
        preview: message.content.truncate(50),
        timestamp: message.created_at
      }

      expect {
        described_class.broadcast_to_server(
          server.id,
          'new_message',
          notification_data
        )
      }.to have_broadcasted_to("notifications:user:#{other_user.id}")
        .with(
          a_hash_including(
            'type' => 'new_message',
            'server_id' => server.id,
            'data' => a_hash_including(
              'message_id' => message.id,
              'sender' => a_hash_including('id' => user.id)
            )
          )
        )
    end

    it 'includes timestamp in notifications' do
      expect {
        described_class.broadcast_to_server(
          server.id,
          'new_message',
          { message_id: message.id }
        )
      }.to have_broadcasted_to("notifications:user:#{other_user.id}")
        .with(
          a_hash_including(
            'timestamp' => be_present
          )
        )
    end
  end

  describe 'notification handling' do
    let(:other_user) { create(:user) }
    
    before do
      server.users << [user, other_user]
      subscribe
    end

    context 'when new message is created' do
      let(:message) { build(:message, server: server, user: other_user) }

      it 'receives notification for new message' do
        expect {
          message.save!
        }.to have_broadcasted_to("notifications:user:#{user.id}")
          .with(
            a_hash_including(
              'type' => 'new_message',
              'data' => a_hash_including(
                'sender' => a_hash_including(
                  'username' => other_user.username
                )
              )
            )
          )
      end

      it 'includes message preview in notification' do
        message.content = 'This is a test message that should be truncated in the preview'
        
        expect {
          message.save!
        }.to have_broadcasted_to("notifications:user:#{user.id}")
          .with(
            a_hash_including(
              'data' => a_hash_including(
                'preview' => message.content.truncate(50)
              )
            )
          )
      end

      it 'includes attachment count in preview when no content' do
        message.content = ''
        message.attachments.attach(
          io: StringIO.new('test image'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )

        expect {
          message.save!
        }.to have_broadcasted_to("notifications:user:#{user.id}")
          .with(
            a_hash_including(
              'data' => a_hash_including(
                'preview' => 'Sent 1 attachment'
              )
            )
          )
      end
    end

    context 'when message has mentions' do
      let(:message) { build(:message, server: server, user: other_user, content: "@#{user.username} Hello!") }

      it 'receives notification for mention' do
        expect {
          message.save!
        }.to have_broadcasted_to("notifications:user:#{user.id}")
          .with(
            a_hash_including(
              'type' => 'new_message',
              'data' => a_hash_including(
                'preview' => include(user.username)
              )
            )
          )
      end
    end
  end
end 