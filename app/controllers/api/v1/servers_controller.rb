# frozen_string_literal: true

module Api
  module V1
    class ServersController < BaseController

      before_action :set_organization

      # GET /api/v1/organizations/:organization_id/servers
      def index
        @servers = @organization.servers.present.order(:name)
        render_success(@servers.map { |s| server_data(s) })
      end

      # GET /api/v1/organizations/:organization_id/servers/:id
      def show
        @server = @organization.servers.find_by_permalink!(params[:id])
        render_success(server_data(@server))
      end

      # POST /api/v1/organizations/:organization_id/servers
      def create
        @server = @organization.servers.build(server_params)
        if @server.save
          render_success(server_data(@server), status: 201)
        else
          render_error "RecordInvalid", message: @server.errors.full_messages.join(", "), status: 422
        end
      end

      # PATCH /api/v1/organizations/:organization_id/servers/:id
      def update
        @server = @organization.servers.find_by_permalink!(params[:id])
        if @server.update(server_params)
          render_success(server_data(@server))
        else
          render_error "RecordInvalid", message: @server.errors.full_messages.join(", "), status: 422
        end
      end

      # DELETE /api/v1/organizations/:organization_id/servers/:id
      def destroy
        @server = @organization.servers.find_by_permalink!(params[:id])
        @server.soft_destroy
        render_success({ message: "Server deleted successfully." })
      end

      # POST /api/v1/organizations/:organization_id/servers/:id/suspend
      def suspend
        admin_required
        @server = @organization.servers.find_by_permalink!(params[:id])
        @server.suspend(params[:reason] || "Suspended via API")
        render_success({ message: "Server suspended successfully." })
      end

      # POST /api/v1/organizations/:organization_id/servers/:id/unsuspend
      def unsuspend
        admin_required
        @server = @organization.servers.find_by_permalink!(params[:id])
        @server.unsuspend
        render_success({ message: "Server unsuspended successfully." })
      end

      private

      def set_organization
        @organization = current_user.organizations_scope.find_by_permalink!(params[:organization_id])
      end

      def server_params
        params.require(:server).permit(:name, :permalink, :mode, :ip_pool_id, :send_limit, :message_retention_days)
      end

      def server_data(server)
        {
          name: server.name,
          permalink: server.permalink,
          uuid: server.uuid,
          mode: server.mode,
          suspended: server.suspended?,
          suspension_reason: server.suspension_reason,
          created_at: server.created_at
        }
      end

    end
  end
end
