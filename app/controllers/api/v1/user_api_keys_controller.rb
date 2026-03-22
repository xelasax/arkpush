# frozen_string_literal: true

module API
  module V1
    class UserAPIKeysController < BaseController

      # GET /api/v1/user/api_keys
      def index
        keys = current_user.user_api_keys.order(created_at: :desc)
        render_success(keys.map { |k| key_data(k) })
      end

      # POST /api/v1/user/api_keys
      def create
        key = current_user.user_api_keys.build(name: params[:name] || "Unnamed Key")
        if key.save
          render_success(key_data(key).merge(key: key.key), status: 201)
        else
          render_error "RecordInvalid", message: key.errors.full_messages.join(", "), status: 422
        end
      end

      # DELETE /api/v1/user/api_keys/:id
      def destroy
        key = current_user.user_api_keys.find_by!(key: params[:id])
        key.destroy
        render_success({ message: "API key revoked successfully." })
      end

      private

      def key_data(key)
        {
          name: key.name,
          last_used_at: key.last_used_at,
          created_at: key.created_at
        }
      end

    end
  end
end
