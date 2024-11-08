class UsersController < ApplicationController
  def create
    user = User.new(user_params)
    if user.save
      session[:user_id] = user.id
      render json: user, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    if @current_user
      servers_with_messages = @current_user.servers.map do |server|
        server.as_json.merge(
          latest_message: server.messages.order(created_at: :desc).first&.as_json(include: { user: { only: :username } })
        )
      end
      
      render json: {
        user: @current_user,
        servers: servers_with_messages
      }
    else
      render json: { message: "Not authorized" }, status: :unauthorized
    end
  end

  private

  def user_params
    params.permit(:username, :password, :email)
  end
end
