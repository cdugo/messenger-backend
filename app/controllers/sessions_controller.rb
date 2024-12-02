class SessionsController < ApplicationController
  class InvalidCredentialsError < StandardError; end

  def create
    user = User.find_by(username: params[:username])
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      render json: user, status: :created
    else
      raise InvalidCredentialsError, 'Invalid username or password'
    end
  end

  def destroy
    session.delete(:user_id)
    head :no_content
  end

  private

  rescue_from InvalidCredentialsError do |e|
    respond_with_error(:unauthorized, 'Authentication Failed', e)
  end
end 