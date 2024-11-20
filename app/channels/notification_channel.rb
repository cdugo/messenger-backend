class NotificationChannel < ApplicationCable::Channel
  def subscribed
    # Only allow authenticated users
    return reject unless current_user
    
    # Subscribe to a single stream for the user
    stream_from "notifications:user:#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  def self.broadcast_to_server(server_id, notification_type, data)
    # Get all users in the server
    server = Server.find(server_id)
    
    # Broadcast to each user's notification stream
    server.users.each do |user|
      ActionCable.server.broadcast(
        "notifications:user:#{user.id}",
        {
          type: notification_type,
          server_id: server_id,
          data: data,
          timestamp: Time.current
        }
      )
    end
  end
end 