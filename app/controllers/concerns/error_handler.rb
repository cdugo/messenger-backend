module ErrorHandler
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError do |e|
      respond_with_error(:internal_server_error, 'Internal Server Error', e)
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      respond_with_error(:not_found, 'Resource not found', e)
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

    rescue_from JWT::DecodeError do |e|
      respond_with_error(:unauthorized, 'Invalid authentication token', e)
    end

    rescue_from JWT::ExpiredSignature do |e|
      respond_with_error(:unauthorized, 'Authentication token has expired', e)
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