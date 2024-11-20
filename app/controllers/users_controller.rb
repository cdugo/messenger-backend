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
      read_states = ServerReadState.where(user: @current_user, server: @current_user.servers)
                                 .index_by(&:server_id)

      servers_with_messages = @current_user.servers.map do |server|
        read_state = read_states[server.id]
        server.as_json.merge(
          latest_message: server.messages.order(created_at: :desc).first&.as_json(include: { user: { only: :username } }),
          read_state: {
            last_read_at: read_state&.last_read_at,
            unread_count: read_state&.unread_count || 0
          }
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
