# frozen_string_literal: true

module API
  module V1
    class UserController < BaseController

      # GET /api/v1/user
      def show
        render_success(user_data(current_user))
      end

      # PATCH /api/v1/user
      def update
        if current_user.update(user_params)
          render_success(user_data(current_user))
        else
          render_error "RecordInvalid", message: current_user.errors.full_messages.join(", "), status: 422
        end
      end

      # POST /api/v1/user/join
      def join
        # This implementation depends on how UserInvites are accepted in the headless UI.
        # We'll skip for now as it requires more complex logic around password setting.
        render_error "NotImplemented", message: "Invitation acceptance via API is not yet implemented.", status: 501
      end

      private

      def user_params
        params.require(:user).permit(:first_name, :last_name, :email_address, :time_zone, :password, :password_confirmation)
      end

      def user_data(user)
        {
          uuid: user.uuid,
          first_name: user.first_name,
          last_name: user.last_name,
          email_address: user.email_address,
          time_zone: user.time_zone,
          admin: user.admin?,
          created_at: user.created_at
        }
      end

    end
  end
end
