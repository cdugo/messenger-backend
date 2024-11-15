class MessagesController < ApplicationController
  before_action :set_server
  before_action :is_member_of_server?
  before_action :can_modify_message?, only: [:update, :destroy]

  def index
    @messages = @server.messages.includes(:user, :replies, :reactions)
    render json: @messages, include: [:user, :replies, :reactions]
  end

  private

  def set_server
    @server = Server.find(params[:server_id])
  end

  def message_params
    params.require(:message).permit(:content, :parent_message_id)
  end

  def can_modify_message?
    unless @message.user_id == @current_user.id
      render json: { message: "You don't have permission to modify this message" }, status: :unauthorized
      return false
    end
    true
  end

  def is_member_of_server?
    unless @server.users.include?(@current_user)
      render json: { message: "You are not a member of this server" }, status: :unauthorized
      return false
    end
    true
  end

  def set_message
    @message = Message.find(params[:id])
  end

end
