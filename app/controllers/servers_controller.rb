class ServersController < ApplicationController
  include MessageSerialization
  before_action :set_server, except: %i[ index create ]
  before_action :can_edit_server?, only: %i[ update destroy transfer_ownership ]
  before_action :is_member_of_server?, only: %i[ leave show]

  # GET /servers
  def index
    @servers = Server.all.includes(:users, :server_read_states)
    read_states = ServerReadState.where(user: @current_user, server: @servers)
                                .index_by(&:server_id)

    render json: @servers.map { |server|
      read_state = read_states[server.id]
      server.as_json.merge(
        users: server.users.map { |user| 
          {
            id: user.id,
            username: user.username,
            email: user.email
          }
        },
        read_state: {
          last_read_at: read_state&.last_read_at,
          unread_count: read_state&.unread_count || 0
        }
      )
    }
  end

  # GET /servers/1
  def show
    read_state = @server.server_read_states.find_by(user: @current_user)
    
    render json: @server.as_json.merge(
      users: @server.users,
      read_state: {
        last_read_at: read_state&.last_read_at,
        unread_count: read_state&.unread_count || 0
      }
    )
  end

  # POST /servers
  def create
    @server = Server.new(server_params)
    @server.users << @current_user
    @server.owner_id = @current_user.id

    if @server.save
      read_state = @server.server_read_states.find_by(user: @current_user)
      render json: @server.as_json.merge(
        users: @server.users,
        read_state: {
          last_read_at: read_state&.last_read_at,
          unread_count: read_state&.unread_count || 0
        }
      ), status: :created
    else
      raise ActiveRecord::RecordInvalid.new(@server)
    end
  end

  # PATCH/PUT /servers/1
  def update
    if @server.update(server_params)
      render json: @server
    else
      raise ActiveRecord::RecordInvalid.new(@server)
    end
  end

  def join
    @server.users << @current_user
    @server.create_read_state_for_user(@current_user)
    read_state = @server.server_read_states.find_by(user: @current_user)
    render json: @server.as_json.merge(
      users: @server.users,
      read_state: {
        last_read_at: read_state&.last_read_at,
        unread_count: read_state&.unread_count || 0
      }
    ), status: :created
  end

  def leave
    if @server.owner_id == @current_user.id
      raise Errors::ServerOwnershipError, 'Cannot leave server that you own'
    elsif !@server.users.include?(@current_user)
      raise Errors::NotServerMemberError, 'You are not a member of this server'
    else
      @server.users.delete(@current_user)
      render json: @server, status: :ok, include: :users
    end
  end

  def transfer_ownership
    new_owner = User.find(params[:owner_id])
    
    if !@server.users.include?(new_owner)
      raise Errors::NotServerMemberError, 'User is not a member of this server'
    else
      @server.update!(owner_id: new_owner.id)
      render json: @server, status: :ok
    end
  end

  # DELETE /servers/1
  def destroy
    @server.destroy!
  end

  private
    def set_server
      @server = Server.find(params[:id])
    end

    def server_params
      params.require(:server).permit(:name, :description, :user_id, :owner_id)
    end

    def can_edit_server?
      unless @server.owner_id == @current_user.id
        raise Errors::ServerOwnershipError, "You don't have permission to modify this server"
      end
      true
    end

    def is_member_of_server?
      unless @server.users.include?(@current_user)
        raise Errors::NotServerMemberError, 'You are not a member of this server'
      end
      true
    end
end
