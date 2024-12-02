require 'rails_helper'

RSpec.describe SessionsController, type: :request do
  let(:user) { create(:user, password: 'password123') }
  let(:valid_credentials) {
    {
      username: user.username,
      password: 'password123'
    }
  }

  describe 'POST /login' do
    context 'with valid credentials' do
      it 'creates a new session' do
        post login_path, params: valid_credentials
        expect(response).to have_http_status(:created)
      end

      it 'returns the user' do
        post login_path, params: valid_credentials
        expect(json_response['username']).to eq(user.username)
        expect(json_response['email']).to eq(user.email)
        expect(json_response).not_to include('password_digest')
      end

      it 'sets the user session' do
        post login_path, params: valid_credentials
        expect(session[:user_id]).to eq(user.id)
      end
    end

    context 'with invalid credentials' do
      it 'returns unauthorized for wrong password' do
        post login_path, params: { username: user.username, password: 'wrong' }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to include('Invalid username or password')
      end

      it 'returns unauthorized for non-existent user' do
        post login_path, params: { username: 'nonexistent', password: 'password123' }
        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to include('Invalid username or password')
      end

      it 'does not set session for invalid credentials' do
        post login_path, params: { username: user.username, password: 'wrong' }
        expect(session[:user_id]).to be_nil
      end
    end
  end

  describe 'DELETE /logout' do
    context 'when user is logged in' do
      before do
        post login_path, params: valid_credentials
      end

      it 'destroys the session' do
        delete logout_path
        expect(response).to have_http_status(:no_content)
        expect(session[:user_id]).to be_nil
      end
    end

    context 'when no user is logged in' do
      it 'returns success' do
        delete logout_path
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end 