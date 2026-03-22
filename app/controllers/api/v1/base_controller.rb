# frozen_string_literal: true

module API
  module V1
    class BaseController < ActionController::API

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
      rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
      rescue_from StandardError, with: :render_standard_error

      # API controllers are stateless and don't use cookies, but we provide a dummy
      # cookies method to satisfy authie's internal requirements.
      def cookies
        @dummy_cookies ||= {}
      end

      # Override authie methods to ensure no cookie-based logic is executed
      def set_browser_id; yield; end
      def auth_session; nil; end
      def validate_auth_session; end
      def touch_auth_session; end
      def store_user_last_used_at; end

      before_action :authenticate_with_api_key

      private

      def authenticate_with_api_key
        header = request.headers["Authorization"]
        token = header&.split(" ")&.last || params[:api_key]

        if token.blank?
          render_error "MissingAPIKey", message: "An API key is required to access this resource.", status: 401
          return
        end

        @current_api_key = UserAPIKey.find_by(key: token)
        if @current_api_key.nil?
          render_error "InvalidAPIKey", message: "The API key provided is invalid.", status: 401
          return
        end

        @current_api_key.use
        @current_user = @current_api_key.user
      end

      def current_user
        @current_user
      end

      def render_error(code, message: nil, status: 422, data: {})
        render json: {
          status: "error",
          error: {
            code: code,
            message: message
          },
          data: data
        }, status: status
      end

      def render_success(data = {}, status: 200)
        render json: {
          status: "success",
          data: data
        }, status: status
      end

      def render_not_found
        render_error "NotFound", message: "The requested resource could not be found.", status: 404
      end

      def render_parameter_missing(exception)
        render_error "ParameterMissing", message: exception.message, status: 400
      end

      def render_record_invalid(exception)
        render_error "RecordInvalid", message: exception.record.errors.full_messages.join(", "), status: 422
      end

      def render_standard_error(exception)
        logger.error "API Error: #{exception.class}: #{exception.message}\n#{exception.backtrace.first(10).join("\n")}"
        render_error "InternalError", message: exception.message, status: 500
      end

      def admin_required
        return if current_user&.admin?

        render_error "AdminRequired", message: "Administrator permissions are required to access this resource.", status: 403
        return
      end

    end
  end
end
