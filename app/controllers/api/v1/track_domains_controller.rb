# frozen_string_literal: true

module Api
  module V1
    class TrackDomainsController < BaseController

      before_action :set_organization
      before_action :set_server
      before_action :set_track_domain, only: [:show, :destroy, :toggle_ssl, :check]

      # GET /api/v1/organizations/:organization_id/servers/:server_id/track_domains
      def index
        @track_domains = @server.track_domains.order(:name)
        render_success(@track_domains.map { |d| track_domain_data(d) })
      end

      # GET /api/v1/organizations/:organization_id/servers/:server_id/track_domains/:id
      def show
        render_success(track_domain_data(@track_domain))
      end

      # POST /api/v1/organizations/:organization_id/servers/:server_id/track_domains
      def create
        @track_domain = @server.track_domains.build(track_domain_params)
        if @track_domain.save
          render_success(track_domain_data(@track_domain), status: 201)
        else
          render_error "RecordInvalid", message: @track_domain.errors.full_messages.join(", "), status: 422
        end
      end

      # DELETE /api/v1/organizations/:organization_id/servers/:server_id/track_domains/:id
      def destroy
        @track_domain.destroy
        render_success({ message: "Track domain deleted successfully." })
      end

      # POST /api/v1/organizations/:organization_id/servers/:server_id/track_domains/:id/toggle_ssl
      def toggle_ssl
        @track_domain.update!(ssl_enabled: !@track_domain.ssl_enabled)
        render_success({ message: "SSL toggled successfully.", ssl_enabled: @track_domain.ssl_enabled })
      end

      # POST /api/v1/organizations/:organization_id/servers/:server_id/track_domains/:id/check
      def check
        if @track_domain.check_dns
          render_success({ message: "DNS check successful.", domain: track_domain_data(@track_domain) })
        else
          render_error "DNSCheckFailed", message: "DNS check failed for this track domain.", data: { error: @track_domain.dns_error }
        end
      end

      private

      def set_organization
        @organization = current_user.organizations_scope.find_by_permalink!(params[:organization_id])
      end

      def set_server
        @server = @organization.servers.find_by_permalink!(params[:server_id])
      end

      def set_track_domain
        @track_domain = @server.track_domains.find_by_uuid!(params[:id])
      end

      def track_domain_params
        params.require(:track_domain).permit(:name, :domain_id, :track_clicks, :track_loads)
      end

      def track_domain_data(domain)
        {
          name: domain.name,
          uuid: domain.uuid,
          ssl_enabled: domain.ssl_enabled,
          dns_status: domain.dns_status,
          dns_error: domain.dns_error,
          track_clicks: domain.track_clicks,
          track_loads: domain.track_loads,
          created_at: domain.created_at
        }
      end

    end
  end
end
