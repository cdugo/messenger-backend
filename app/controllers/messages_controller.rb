class MessagesController < ApplicationController
  include MessageSerialization
  before_action :authenticate_user
  before_action :set_server
  before_action :is_member_of_server?

  # GET /servers/:server_id/messages
  def index
    @messages = @server.messages
                      .includes(:user, reactions: { user: {} })
                      .order(created_at: :desc)
                      .page(params[:page])
                      .per(Pagination::DEFAULT_PAGE_SIZE)

    render json: {
      messages: @messages.as_json(message_includes),
      pagination: {
        current_page: @messages.current_page,
        total_pages: @messages.total_pages,
        total_count: @messages.total_count,
        next_page: @messages.next_page,
        prev_page: @messages.prev_page,
        per_page: Pagination::DEFAULT_PAGE_SIZE,
        actual_size: @messages.size
      }
    }
  end

  private

  def set_server
    @server = Server.find(params[:server_id])
  end

  def is_member_of_server?
    unless @server.users.include?(@current_user)
      raise ::Errors::NotServerMemberError, 'You are not a member of this server'
    end
    true
  end
end
