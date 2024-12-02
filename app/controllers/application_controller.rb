class ApplicationController < ActionController::API
  include ErrorHandler
  
  before_action :set_current_user

  private

  def set_current_user
    @current_user = User.find_by(id: session[:user_id])
  end

  def authenticate_user
    raise Errors::AuthenticationError, 'Not authorized' unless @current_user
  end
end
