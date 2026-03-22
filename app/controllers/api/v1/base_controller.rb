# frozen_string_literal: true

module API
  module V1
    class BaseController < ActionController::API

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

      # API controllers are stateless and don't use cookies, so we skip authie's browser tracking and session validation
      skip_before_action :set_browser_id, raise: false
      skip_before_action :auth_session, raise: false
      skip_before_action :store_user_last_used_at, raise: false
      skip_before_action :validate_auth_session, raise: false
      skip_after_action :touch_auth_session, raise: false

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

      def admin_required
        return if current_user&.admin?

        render_error "AdminRequired", message: "Administrator permissions are required to access this resource.", status: 403
        throw(:abort)
      end

    end
  end
end
