require 'ostruct'

class MessageChannel < ApplicationCable::Channel
    def subscribed
        begin
            server = Server.find(params[:server_id])
            if server.users.include?(current_user)
                stream_name = "server_#{params[:server_id]}"
                puts "Successfully subscribed to #{stream_name}"
                stream_from stream_name

                # Add read state handling
                read_state = server.server_read_states.find_by!(user: current_user)
                read_state.mark_as_read!
                @server_id = params[:server_id]
                
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
        return unless server.users.include?(current_user)

        handler_class.new(parsed_data, server, current_user).call

    rescue JSON::ParserError => e
        puts "❌ JSON parse error: #{e.message}"
        deliver_error_message(OpenStruct.new(server_id: parsed_data['server_id']), "Invalid message format")
    rescue => e
        puts "❌ Error: #{e.message}"
        deliver_error_message(OpenStruct.new(server_id: parsed_data['server_id']), "Error processing message: #{e.message}")
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
