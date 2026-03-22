# frozen_string_literal: true

module Api
  module V1
    class UsersController < BaseController

      before_action :admin_required

      # GET /api/v1/users
      def index
        @users = User.order(:first_name, :last_name)
        render_success(@users.map { |u| user_data(u) })
      end

      # GET /api/v1/users/:id
      def show
        @user = User.find_by_uuid!(params[:id])
        render_success(user_data(@user))
      end

      # POST /api/v1/users
      def create
        @user = User.new(user_params)
        if @user.save
          render_success(user_data(@user), status: 201)
        else
          render_error "RecordInvalid", message: @user.errors.full_messages.join(", "), status: 422
        end
      end

      # PATCH /api/v1/users/:id
      def update
        @user = User.find_by_uuid!(params[:id])
        if @user.update(user_params)
          render_success(user_data(@user))
        else
          render_error "RecordInvalid", message: @user.errors.full_messages.join(", "), status: 422
        end
      end

      # DELETE /api/v1/users/:id
      def destroy
        @user = User.find_by_uuid!(params[:id])
        if @user == current_user
          render_error "CannotDeleteSelf", message: "You cannot delete your own user account.", status: 400
          return
        end

        @user.destroy!
        render_success({ message: "User deleted successfully." })
      end

      private

      def user_params
        params.require(:user).permit(:email_address, :first_name, :last_name, :admin, :password, :password_confirmation, organization_ids: [])
      end

      def user_data(user)
        {
          uuid: user.uuid,
          first_name: user.first_name,
          last_name: user.last_name,
          email_address: user.email_address,
          admin: user.admin?,
          created_at: user.created_at
        }
      end

    end
  end
end
