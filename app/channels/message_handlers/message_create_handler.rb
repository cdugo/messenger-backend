module MessageHandlers
  class MessageCreateHandler < BaseHandler
    include Rails.application.routes.url_helpers

    def call
      message = Message.new(
        content: data['content'],
        user: current_user,
        server_id: data['server_id'],
        parent_message_id: data['parent_message_id']
      )

      # Attach files if present
      if data['attachment_ids'].present?
        blobs = data['attachment_ids'].map do |signed_id|
          ActiveStorage::Blob.find_signed!(signed_id)
        end
        message.attachments.attach(blobs)
      end

      # Save the message after attaching files
      message.save!

      # Broadcast the message to the message channel
      broadcast_message(message)

      # Broadcast notification using the channel directly
      NotificationChannel.broadcast_to_server(
        message.server_id,
        'new_message',
        {
          message_id: message.id,
          server_id: message.server_id,
          sender: {
            id: message.user.id,
            username: message.user.username
          },
          preview: generate_preview(message),
          timestamp: message.created_at
        }
      )

    rescue ActiveRecord::RecordInvalid => e
      error_response(e.message)
    rescue ActiveSupport::MessageVerifier::InvalidSignature => e
      error_response("Invalid attachment")
    end

    private

    def generate_preview(message)
      if message.content.present?
        message.content.truncate(50)
      else
        attachment_count = message.attachments.count
        "Sent #{attachment_count} #{attachment_count == 1 ? 'attachment' : 'attachments'}"
      end
    end

    def broadcast_message(message)
      host_options = { host: 'localhost:8080' }

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
          },
          attachments: message.attachments.map { |attachment|
            {
              id: attachment.id,
              filename: attachment.filename.to_s,
              content_type: attachment.content_type,
              byte_size: attachment.byte_size,
              url: rails_blob_url(attachment, host_options),
              thumbnail_url: attachment.representable? ? 
                rails_representation_url(attachment.representation(:thumb), host_options) : nil
            }
          }
        }
      )
    end
  end
end 