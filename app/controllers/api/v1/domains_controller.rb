# frozen_string_literal: true

module API
  module V1
    class DomainsController < BaseController

      before_action :set_organization
      before_action :set_server, if: -> { params[:server_id].present? }
      before_action :set_domain, only: [:show, :destroy, :verify, :check]

      # GET /api/v1/organizations/:organization_id/domains
      # OR /api/v1/organizations/:organization_id/servers/:server_id/domains
      def index
        @domains = @server ? @server.domains : @organization.domains
        render_success(@domains.map { |d| domain_data(d) })
      end

      # GET /api/v1/organizations/:organization_id/domains/:id
      def show
        render_success(domain_data(@domain))
      end

      # POST /api/v1/organizations/:organization_id/domains
      def create
        scope = @server ? @server.domains : @organization.domains
        @domain = scope.build(params.require(:domain).permit(:name, :verification_method, :dkim_identifier))

        if current_user.admin?
          @domain.verification_method = "DNS"
          @domain.verified_at = Time.now
        end

        if @domain.save
          render_success(domain_data(@domain), status: 201)
        else
          render_error "RecordInvalid", message: @domain.errors.full_messages.join(", "), status: 422
        end
      end

      # DELETE /api/v1/organizations/:organization_id/domains/:id
      def destroy
        @domain.destroy
        render_success({ message: "Domain deleted successfully." })
      end

      # POST /api/v1/organizations/:organization_id/domains/:id/verify
      def verify
        if @domain.verified?
          render_error "AlreadyVerified", message: "This domain has already been verified.", status: 400
          return
        end

        case params[:method] || @domain.verification_method
        when "DNS"
          if @domain.verify_with_dns
            render_success({ message: "Domain verified successfully.", domain: domain_data(@domain) })
          else
            render_error "VerificationFailed", message: "We couldn't verify your domain via DNS. Please check your TXT record."
          end
        when "Email"
          if params[:code]
            if @domain.verification_token == params[:code].to_s.strip
              @domain.mark_as_verified
              render_success({ message: "Domain verified successfully.", domain: domain_data(@domain) })
            else
              render_error "InvalidCode", message: "The verification code provided is incorrect."
            end
          elsif params[:email_address].present?
            unless @domain.verification_email_addresses.include?(params[:email_address])
              render_error "InvalidEmail", message: "The selected email address is not permitted for verification."
              return
            end

            AppMailer.verify_domain(@domain, params[:email_address], current_user).deliver
            render_success({ message: "Verification email sent to #{params[:email_address]}." })
          else
            render_error "MissingParameter", message: "A verification code or email address is required for email verification.", status: 400
          end
        else
          render_error "InvalidMethod", message: "Invalid verification method.", status: 400
        end
      end

      # POST /api/v1/organizations/:organization_id/domains/:id/check
      def check
        if @domain.check_dns(:manual)
          render_success({ message: "DNS records improved successfully.", domain: domain_data(@domain) })
        else
          render_error "DNSCheckFailed", message: "There seems to be an issue with your DNS records.", data: {
            spf: @domain.spf_status,
            dkim: @domain.dkim_status,
            mx: @domain.mx_status
          }
        end
      end

      private

      def set_organization
        @organization = current_user.organizations_scope.find_by_permalink!(params[:organization_id])
      end

      def set_server
        @server = @organization.servers.find_by_permalink!(params[:server_id])
      end

      def set_domain
        scope = @server ? @server.domains : @organization.domains
        @domain = scope.find_by_uuid!(params[:id])
      end

      def domain_data(domain)
        {
          name: domain.name,
          uuid: domain.uuid,
          verified: domain.verified?,
          verification_method: domain.verification_method,
          verification_token: domain.verification_token,
          spf_status: domain.spf_status,
          dkim_status: domain.dkim_status,
          dkim_identifier: domain.dkim_identifier,
          mx_status: domain.mx_status,
          return_path_status: domain.return_path_status,
          created_at: domain.created_at
        }
      end

    end
  end
end
