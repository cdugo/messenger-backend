class MessageChannel < ApplicationCable::Channel
    def subscribed
        begin
          server = Server.find(params[:server_id])
          if server.users.include?(current_user)
            stream_name = "server_#{params[:server_id]}"
            puts "Successfully subscribed to #{stream_name}"
            stream_from stream_name
            
            transmit({ type: 'confirm_subscription', server_id: params[:server_id] })
          else
            puts "Rejecting subscription - user not in server"
            reject
          end
        rescue ActiveRecord::RecordNotFound => e
          puts "Server not found: #{e.message}"
          reject
        rescue => e
          puts "Subscription error: #{e.message}"
          puts e.backtrace.join("\n")
          reject
        end
      end

  def unsubscribed
    stop_all_streams
  end

  MESSAGE_ACTIONS = {
    receive: 'receive',
    update: 'update', 
    delete: 'delete'
  }.freeze

  def receive(data)
    parsed_data = data.is_a?(String) ? JSON.parse(data) : data
    
    server = Server.includes(:users).find(parsed_data['server_id'])
    return unless server.users.include?(current_user)
  
    case parsed_data['action']
    when MESSAGE_ACTIONS[:receive] 
      handle_create(parsed_data, server)
    when MESSAGE_ACTIONS[:update]
      handle_update(parsed_data, server) 
    when MESSAGE_ACTIONS[:delete]
      handle_delete(parsed_data, server)
    end
  rescue JSON::ParserError => e
    puts "❌ JSON parse error: #{e.message}"
    deliver_error_message(OpenStruct.new(server_id: parsed_data['server_id']), "Invalid message format")
  rescue => e
    deliver_error_message(OpenStruct.new(server_id: parsed_data['server_id']), "Error processing message: #{e.message}")
  end

  def handle_create(data, server)
    message = Message.new(
      content: data['content'],
      user: current_user,
      server: server,
      parent_message_id: data['parent_message_id']
    )

    if message.save
      broadcast_message(message)
    else
      deliver_error_message(message)
    end
  end

  def handle_update(data, server)
    message = server.messages.find(data['message_id'])
    return unless message.user_id == current_user.id

    if message.update(content: data['content'])
      broadcast_message(message)
    else
      deliver_error_message(message)
    end
  end

  def handle_delete(data, server)
    message = server.messages.find(data['message_id'])
    return unless message.user_id == current_user.id

    if message.destroy
      ActionCable.server.broadcast(
        "server_#{server.id}",
        {
          type: 'message_deleted',
          message_id: data['message_id']
        }
      )
    else
      deliver_error_message(message)
    end
  end

  private

  def broadcast_message(message)
    ActionCable.server.broadcast(
      "server_#{message.server_id}",
      {
        type: 'message',
        id: message.id,
        content: message.content,
        user_id: message.user_id,
        server_id: message.server_id,
        parent_message_id: message.parent_message_id,
        created_at: message.created_at,
        user: {
          id: message.user.id,
          username: message.user.username
        }
      }
    )
  end

  def deliver_error_message(message, error_text = nil)
    ActionCable.server.broadcast(
      "server_#{message.server_id}",
      { 
        type: 'error', 
        message: error_text || message.errors.full_messages.join(', ')
      }
    )
  end

end
