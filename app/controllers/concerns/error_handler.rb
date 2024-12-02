module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |e|
      respond_with_error(:internal_server_error, 'Internal Server Error', e)
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      respond_with_error(:forbidden, 'Resource not found', e)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      respond_with_error(:unprocessable_entity, 'Validation failed', e)
    end

    rescue_from ActionController::ParameterMissing do |e|
      respond_with_error(:bad_request, 'Missing required parameters', e)
    end

    rescue_from ActiveRecord::RecordNotUnique do |e|
      respond_with_error(:conflict, 'Resource already exists', e)
    end

    rescue_from Errors::AuthenticationError do |e|
      respond_with_error(:unauthorized, 'Authentication required', e)
    end

    rescue_from Errors::NotServerMemberError do |e|
      respond_with_error(:forbidden, 'Not a member of this server', e)
    end

    rescue_from Errors::ServerOwnershipError do |e|
      respond_with_error(:forbidden, 'Server ownership error', e)
    end

    rescue_from Errors::SubscriptionError do |e|
        reject
      handle_error(e, 'Subscription failed')
    end
    
    rescue_from Errors::MessageError do |e|
      handle_error(e)
    end
  end

  private

  def respond_with_error(status, message, error)
    error_response = {
      status: status,
      message: message,
      details: error.message
    }

    error_response[:backtrace] = error.backtrace if Rails.env.development?

    Rails.logger.error("#{message}: #{error.message}")
    Rails.logger.error(error.backtrace.join("\n")) if Rails.env.development?

    render json: error_response, status: status
  end
end 