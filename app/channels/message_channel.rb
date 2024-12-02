require 'ostruct'

class MessageChannel < ApplicationCable::Channel
  def subscribed
    server = Server.find(params[:server_id])
    unless server.users.include?(current_user)
      raise Errors::SubscriptionError, 'User not authorized for this server'
    end

    stream_name = "server_#{params[:server_id]}"
    stream_from stream_name

    # Add read state handling
    read_state = server.server_read_states.find_by!(user: current_user)
    read_state.mark_as_read!
    @server_id = params[:server_id]
    
    transmit({ type: 'confirm_subscription', server_id: params[:server_id] })
  rescue ActiveRecord::RecordNotFound
    raise Errors::SubscriptionError, 'Server not found'
  end

  def unsubscribed
    stop_all_streams
    @server_id = nil
  end

  def message_create(data)
    # Update last_read_at whenever a message is created while subscribed
    if @server_id
      read_state = ServerReadState.find_by(user: current_user, server_id: @server_id)
      read_state&.touch(:last_read_at)
    end

    handle_action(MessageHandlers::MessageCreateHandler, data)
  end

  def message_delete(data)
    handle_action(MessageHandlers::MessageDeleteHandler, data)
  end

  def reaction_create(data)
    handle_action(MessageHandlers::ReactionCreateHandler, data)
  end

  def reaction_delete(data)
    handle_action(MessageHandlers::ReactionDeleteHandler, data)
  end

  private

  def handle_action(handler_class, data)
    parsed_data = data.is_a?(String) ? JSON.parse(data) : data
    
    server = Server.includes(:users).find(parsed_data['server_id'])
    unless server.users.include?(current_user)
      raise Errors::MessageError, 'User not authorized for this server'
    end

    handler_class.new(parsed_data, server, current_user).call

  rescue JSON::ParserError
    raise Errors::MessageError, 'Invalid message format'
  rescue StandardError => e
    raise Errors::MessageError, "Error processing message: #{e.message}"
  end
end
