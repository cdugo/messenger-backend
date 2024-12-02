require 'rails_helper'

RSpec.describe MessagesController, type: :request do
  let(:user) { create(:user) }
  let(:server) { create(:server) }
  let(:valid_attributes) { { content: 'Hello, world!' } }
  let(:invalid_attributes) { { content: '' } }

  before do
    server.users << user
    sign_in user
  end

  describe 'GET /servers/:server_id/messages' do
    context 'when user is a member of the server' do
      before do
        create_list(:message, 3, server: server, user: user)
      end

      it 'returns a successful response' do
        get server_messages_path(server)
        expect(response).to have_http_status(:success)
        expect(json_response['messages'].length).to eq(3)
      end

      it 'includes user information in the response' do
        get server_messages_path(server)
        expect(json_response['messages'].first).to include(
          'user' => include(
            'id' => user.id,
            'username' => user.username
          )
        )
      end

      context 'with pagination' do
        before do
          create_list(:message, 30, server: server, user: user)
        end

        it 'returns paginated results' do
          get server_messages_path(server), params: { page: 1, per_page: 25 }
          expect(json_response['messages'].length).to eq(25)
          expect(json_response['pagination']).to include(
            'current_page' => 1,
            'total_pages' => 2,
            'total_count' => 33,
            'per_page' => 25
          )
        end

        it 'returns the second page' do
          get server_messages_path(server), params: { page: 2, per_page: 25 }
          expect(json_response['messages'].length).to eq(8)
        end
      end

      context 'with message attachments' do
        let!(:message_with_attachment) do
          message = create(:message, server: server, user: user)
          message.attachments.attach(
            io: StringIO.new('test image'),
            filename: 'test.jpg',
            content_type: 'image/jpeg'
          )
          message
        end

        it 'includes attachment urls in the response' do
          get server_messages_path(server)
          message_response = json_response['messages'].find { |m| m['id'] == message_with_attachment.id }
          expect(message_response['attachments']).to be_present
          expect(message_response['attachments'].first).to include(
            'filename' => 'test.jpg',
            'url' => be_present,
            'thumbnail_url' => be_present
          )
        end
      end

      context 'with message reactions' do
        let!(:message_with_reaction) do
          message = create(:message, server: server, user: user)
          create(:message_reaction, message: message, user: user, emoji: '👍')
          message
        end

        it 'includes reactions in the response' do
          get server_messages_path(server)
          message_response = json_response['messages'].find { |m| m['id'] == message_with_reaction.id }
          expect(message_response['reactions']).to be_present
          expect(message_response['reactions'].first).to include(
            'emoji' => '👍',
            'user' => include('username' => user.username)
          )
        end
      end
    end

    context 'when user is not a member of the server' do
      let(:other_server) { create(:server) }

      it 'returns forbidden status' do
        get server_messages_path(other_server)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /servers/:server_id/messages' do
    context 'with valid parameters' do
      it 'creates a new message' do
        expect {
          post server_messages_path(server), params: { message: valid_attributes }
        }.to change(Message, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it 'creates a message with attachment' do
        file = fixture_file_upload('spec/fixtures/files/test_image.jpg', 'image/jpeg')
        expect {
          post server_messages_path(server), params: {
            message: valid_attributes.merge(attachments: [file])
          }
        }.to change(ActiveStorage::Attachment, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it 'creates a reply to another message' do
        parent = create(:message, server: server)
        expect {
          post server_messages_path(server), params: {
            message: valid_attributes.merge(parent_message_id: parent.id)
          }
        }.to change(Message, :count).by(1)
        expect(Message.last.parent_message_id).to eq(parent.id)
      end

      it 'broadcasts the message' do
        expect {
          post server_messages_path(server), params: { message: valid_attributes }
        }.to have_broadcasted_to("server_#{server.id}")
      end
    end

    context 'with invalid parameters' do
      it 'does not create a message without content or attachments' do
        expect {
          post server_messages_path(server), params: { message: invalid_attributes }
        }.not_to change(Message, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create a message with invalid attachment type' do
        file = fixture_file_upload('spec/fixtures/files/test.txt', 'text/plain')
        expect {
          post server_messages_path(server), params: {
            message: valid_attributes.merge(attachments: [file])
          }
        }.not_to change(Message, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not create a reply to message from different server' do
        other_server = create(:server)
        parent = create(:message, server: other_server)
        expect {
          post server_messages_path(server), params: {
            message: valid_attributes.merge(parent_message_id: parent.id)
          }
        }.not_to change(Message, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when user is not a member of the server' do
      let(:other_server) { create(:server) }

      it 'returns forbidden status' do
        post server_messages_path(other_server), params: { message: valid_attributes }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE /servers/:server_id/messages/:id' do
    let!(:message) { create(:message, server: server, user: user) }

    context 'when user owns the message' do
      it 'deletes the message' do
        expect {
          delete server_message_path(server, message)
        }.to change(Message, :count).by(-1)
        expect(response).to have_http_status(:no_content)
      end

      it 'broadcasts the deletion' do
        expect {
          delete server_message_path(server, message)
        }.to have_broadcasted_to("server_#{server.id}")
          .with(a_hash_including(type: 'message_deleted'))
      end
    end

    context 'when user does not own the message' do
      let!(:other_user_message) { create(:message, server: server) }

      it 'returns forbidden status' do
        delete server_message_path(server, other_user_message)
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when message has reactions' do
      let!(:reaction) { create(:message_reaction, message: message, user: create(:user)) }

      it 'deletes associated reactions' do
        expect {
          delete server_message_path(server, message)
        }.to change(MessageReaction, :count).by(-1)
      end
    end

    context 'when message has attachments' do
      before do
        message.attachments.attach(
          io: StringIO.new('test image'),
          filename: 'test.jpg',
          content_type: 'image/jpeg'
        )
      end

      it 'deletes associated attachments' do
        expect {
          delete server_message_path(server, message)
        }.to change(ActiveStorage::Attachment, :count).by(-1)
      end
    end
  end
end 