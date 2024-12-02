module ApplicationCable
  class Channel < ActionCable::Channel::Base
    rescue_from StandardError do |e|
      handle_error(e)
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      handle_error(e, 'Resource not found')
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      handle_error(e, 'Validation failed')
    end

    private

    def handle_error(error, message = 'An error occurred')
      error_data = {
        error: {
          message: message,
          details: error.message
        }
      }

      # Log the error
      Rails.logger.error("WebSocket Error: #{message}: #{error.message}")
      Rails.logger.error(error.backtrace.join("\n")) if Rails.env.development?

      # Transmit error to the client
      transmit error_data
    end

    def handle_subscribe_error
      reject_subscription if subscription_rejected?
    end
  end
end
