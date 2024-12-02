require 'rails_helper'

RSpec.describe UsersController, type: :request do
  let(:valid_attributes) {
    {
      username: 'johndoe',
      email: 'john@example.com',
      password: 'password123'
    }
  }

  let(:invalid_attributes) {
    {
      username: '',
      email: 'invalid-email',
      password: 'short'
    }
  }

  describe 'POST /signup' do
    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post signup_path, params: valid_attributes
        }.to change(User, :count).by(1)
        expect(response).to have_http_status(:created)
      end

      it 'returns the created user' do
        post signup_path, params: valid_attributes
        expect(json_response['username']).to eq(valid_attributes[:username])
        expect(json_response['email']).to eq(valid_attributes[:email])
        expect(json_response).not_to include('password_digest')
      end

      it 'sets the user session' do
        post signup_path, params: valid_attributes
        expect(session[:user_id]).to eq(User.last.id)
      end
    end

    context 'with invalid parameters' do
      it 'does not create a user' do
        expect {
          post signup_path, params: invalid_attributes
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns validation errors' do
        post signup_path, params: invalid_attributes
        expect(json_response['errors']).to be_present
      end
    end

    context 'with duplicate username' do
      before { create(:user, username: valid_attributes[:username]) }

      it 'does not create a user' do
        expect {
          post signup_path, params: valid_attributes
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['errors']).to include('username' => ['has already been taken'])
      end
    end
  end

  describe 'GET /me' do
    let(:user) { create(:user) }
    let!(:server) { create(:server) }

    before do
      server.users << user
      server.create_read_state_for_user(user)
    end

    context 'when user is authenticated' do
      before do
        sign_in user
      end

      it 'returns the current user with servers' do
        get me_path
        expect(response).to have_http_status(:success)
        expect(json_response['user']['id']).to eq(user.id)
        expect(json_response['servers']).to be_present
      end

      it 'includes server read states' do
        get me_path
        server_response = json_response['servers'].first
        expect(server_response['read_state']).to include(
          'last_read_at',
          'unread_count'
        )
      end

      it 'includes latest message for each server' do
        message = create(:message, server: server, user: user)
        get me_path
        server_response = json_response['servers'].first
        expect(server_response['latest_message']).to be_present
        expect(server_response['latest_message']['id']).to eq(message.id)
      end
    end

    context 'when user is not authenticated' do
      it 'returns unauthorized status' do
        get me_path
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end 