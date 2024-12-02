class ApplicationController < ActionController::Base
  include ErrorHandler
  
  skip_before_action :verify_authenticity_token
  before_action :set_current_user

  class AuthenticationError < StandardError; end
  
  private

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end

  def authenticate_user
    raise AuthenticationError, 'Not authorized' unless @current_user
  end

  # Add custom error handling for authentication
  rescue_from AuthenticationError do |e|
    respond_with_error(:unauthorized, 'Authentication required', e)
  end
end
