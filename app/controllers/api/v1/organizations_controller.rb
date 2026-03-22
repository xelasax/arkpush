# frozen_string_literal: true

module API
  module V1
    class OrganizationsController < BaseController
      before_action :admin_required, only: [:create, :destroy]

      # GET /api/v1/organizations
      def index
        warn "DEBUG: OrganizationsController#index reached"
        @organizations = current_user.organizations_scope.present.order(:name)
        render_success(@organizations.map { |o| organization_data(o) })
      end

      # GET /api/v1/organizations/:id
      def show
        @organization = current_user.organizations_scope.find_by_permalink!(params[:id])
        render_success(organization_data(@organization))
      end

      # POST /api/v1/organizations
      def create
        @organization = Organization.new(params.require(:organization).permit(:name, :permalink))
        @organization.owner = current_user
        if @organization.save
          render_success(organization_data(@organization), status: 201)
        else
          render_error "RecordInvalid", message: @organization.errors.full_messages.join(", "), status: 422
        end
      end

      # PATCH /api/v1/organizations/:id
      def update
        @organization = current_user.organizations_scope.find_by_permalink!(params[:id])
        if @organization.update(params.require(:organization).permit(:name, :time_zone))
          render_success(organization_data(@organization))
        else
          render_error "RecordInvalid", message: @organization.errors.full_messages.join(", "), status: 422
        end
      end

      # DELETE /api/v1/organizations/:id
      def destroy
        @organization = Organization.find_by_permalink!(params[:id])
        @organization.soft_destroy
        render_success({ message: "Organization deleted successfully." })
      end

      # PATCH /api/v1/organizations/:id/settings
      def settings
        update # Alias for update or same logic
      end

      private

      def organization_data(organization)
        {
          name: organization.name,
          permalink: organization.permalink,
          uuid: organization.uuid,
          time_zone: organization.time_zone,
          suspended: organization.suspended?,
          created_at: organization.created_at
        }
      end

    end
  end
end
