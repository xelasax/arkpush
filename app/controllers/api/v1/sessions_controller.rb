# frozen_string_literal: true

module API
  module V1
    class SessionsController < BaseController

      skip_before_action :authenticate_with_api_key, only: [:create, :begin_password_reset, :finish_password_reset]

      # POST /api/v1/sessions
      def create
        email = params.dig(:credentials, :email_address) || params.dig(:credentials, :email) || params[:email_address] || params[:email]
        password = params.dig(:credentials, :password) || params[:password]
        
        user = User.authenticate(email, password)
        
        # In a headless system, we provide a way to get an API key. 
        # We'll return the first one or create a default one.
        api_key = user.user_api_keys.first || user.user_api_keys.create!(name: "Default API Key")
        
        render_success({
          user: {
            uuid: user.uuid,
            first_name: user.first_name,
            last_name: user.last_name,
            email_address: user.email_address,
            admin: user.admin?
          },
          api_key: api_key.key
        })
      rescue Postal::Errors::AuthenticationError
        render_error "AuthenticationFailed", message: "Invalid email address or password.", status: 401
      end

      # DELETE /api/v1/sessions
      def destroy
        # revoking isn't strictly necessary for a bearer token but we can acknowledge it
        render_success({ message: "Logged out successfully." })
      end

      # POST /api/v1/sessions/reset
      def begin_password_reset
        user = User.find_by(email_address: params[:email_address])
        if user.nil?
          render_error "UserNotFound", message: "No user found with that email address.", status: 404
          return
        end

        user.begin_password_reset
        render_success({ message: "Password reset email sent." })
      end

      # PUT /api/v1/sessions/reset
      def finish_password_reset
        user = User.where(password_reset_token: params[:token]).where("password_reset_token_valid_until > ?", Time.now).first
        if user.nil?
          render_error "InvalidToken", message: "The token is invalid or has expired.", status: 400
          return
        end

        if params[:password].blank?
          render_error "PasswordMissing", message: "A new password is required.", status: 400
          return
        end

        user.password = params[:password]
        user.password_confirmation = params[:password_confirmation]
        if user.save
          render_success({ message: "Password has been reset successfully." })
        else
          render_error "RecordInvalid", message: user.errors.full_messages.join(", "), status: 422
        end
      end

    end
  end
end
