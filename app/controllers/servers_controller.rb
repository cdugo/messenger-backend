class ServersController < ApplicationController
  before_action :set_server, except: %i[ index create ]
  before_action :can_edit_server?, only: %i[ update destroy transfer_ownership ]
  before_action :is_member_of_server?, only: %i[ leave show]
  # GET /servers
  def index
    @servers = Server.all
    

    render json: @servers
  end

  # GET /servers/1
  def show
    render json: @server, include: [:users, :messages]
  end

  # POST /servers
  def create
    @server = Server.new(server_params)
    @server.users << @current_user
    @server.owner_id = @current_user.id

    if @server.save
      render json: @server, status: :created, include: :users
    else
      render json: @server.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /servers/1
  def update
    if @server.update(server_params)
      render json: @server
    else
      render json: @server.errors, status: :unprocessable_entity
    end
  end

  def join
    begin
      @server.users << @current_user
      render json: @server, status: :created, include: :users
    rescue ActiveRecord::RecordNotUnique
      render json: { message: "You are already a member of this server" }, status: :unprocessable_entity
    end
  end

  def leave
    if @server.owner_id == @current_user.id
      render json: { message: "Cannot leave server that you own" }, status: :unauthorized

    elsif !@server.users.include?(@current_user)
      render json: { message: "You are not a member of this server" }, status: :unauthorized
    else
      @server.users.delete(@current_user)
      render json: @server, status: :ok, include: :users
    end
  end

  def transfer_ownership
    new_owner = User.find(params[:owner_id])
    
    if !@server.users.include?(new_owner)
      render json: { message: "User is not a member of this server" }, status: :unauthorized
    else
      @server.update(owner_id: new_owner.id)
      render json: @server, status: :ok
    end
  rescue ActiveRecord::RecordNotFound
    render json: { message: "User not found" }, status: :not_found
  end

  # DELETE /servers/1
  def destroy
    @server.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_server
      @server = Server.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def server_params
      params.require(:server).permit(:name, :description, :user_id, :owner_id)
    end

    def can_edit_server?
      unless @server.owner_id == @current_user.id
        render json: { message: "You don't have permission to modify this server" }, status: :unauthorized
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
end
