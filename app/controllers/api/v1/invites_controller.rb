# frozen_string_literal: true

module API
  module V1
    class InvitesController < BaseController

      before_action :set_organization

      # GET /api/v1/organizations/:organization_id/invites
      def index
        @invites = @organization.user_invites.order(created_at: :desc)
        render_success(@invites.map { |i| invite_data(i) })
      end

      # POST /api/v1/organizations/:organization_id/invites
      def create
        @invite = @organization.user_invites.build(params.require(:invite).permit(:email_address))
        if @invite.save
          AppMailer.user_invite(@invite).deliver
          render_success(invite_data(@invite), status: 201)
        else
          render_error "RecordInvalid", message: @invite.errors.full_messages.join(", "), status: 422
        end
      end

      # DELETE /api/v1/organizations/:organization_id/invites/:id
      def destroy
        @invite = @organization.user_invites.find_by_uuid!(params[:id])
        @invite.destroy
        render_success({ message: "Invitation revoked successfully." })
      end

      private

      def set_organization
        @organization = current_user.organizations_scope.find_by_permalink!(params[:organization_id])
      end

      def invite_data(invite)
        {
          uuid: invite.uuid,
          email_address: invite.email_address,
          expires_at: invite.expires_at,
          created_at: invite.created_at
        }
      end

    end
  end
end
