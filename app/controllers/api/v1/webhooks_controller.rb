# frozen_string_literal: true

module API
  module V1
    class WebhooksController < BaseController

      before_action :set_organization
      before_action :set_server
      before_action :set_webhook, only: [:show, :update, :destroy]

      # GET /api/v1/organizations/:organization_id/servers/:server_id/webhooks
      def index
        @webhooks = @server.webhooks.order(:name)
        render_success(@webhooks.map { |w| webhook_data(w) })
      end

      # GET /api/v1/organizations/:organization_id/servers/:server_id/webhooks/:id
      def show
        render_success(webhook_data(@webhook))
      end

      # POST /api/v1/organizations/:organization_id/servers/:server_id/webhooks
      def create
        @webhook = @server.webhooks.build(webhook_params)
        if @webhook.save
          render_success(webhook_data(@webhook), status: 201)
        else
          render_error "RecordInvalid", message: @webhook.errors.full_messages.join(", "), status: 422
        end
      end

      # PATCH /api/v1/organizations/:organization_id/servers/:server_id/webhooks/:id
      def update
        if @webhook.update(webhook_params)
          render_success(webhook_data(@webhook))
        else
          render_error "RecordInvalid", message: @webhook.errors.full_messages.join(", "), status: 422
        end
      end

      # DELETE /api/v1/organizations/:organization_id/servers/:server_id/webhooks/:id
      def destroy
        @webhook.destroy
        render_success({ message: "Webhook deleted successfully." })
      end

      # GET /api/v1/organizations/:organization_id/servers/:server_id/webhooks/history
      def history
        @requests = @server.webhook_requests.order(created_at: :desc).limit(50)
        render_success(@requests.map { |r| request_data(r) })
      end

      # GET /api/v1/organizations/:organization_id/servers/:server_id/webhooks/history/:uuid
      def history_request
        @request = @server.webhook_requests.find_by_uuid!(params[:uuid])
        render_success(request_data(@request).merge(payload: @request.payload))
      end

      private

      def set_organization
        @organization = current_user.organizations_scope.find_by_permalink!(params[:organization_id])
      end

      def set_server
        @server = @organization.servers.find_by_permalink!(params[:server_id])
      end

      def set_webhook
        @webhook = @server.webhooks.find_by_uuid!(params[:id])
      end

      def webhook_params
        params.require(:webhook).permit(:name, :url, :enabled, :all_events, :sign, event_ids: [])
      end

      def webhook_data(webhook)
        {
          name: webhook.name,
          uuid: webhook.uuid,
          url: webhook.url,
          enabled: webhook.enabled,
          all_events: webhook.all_events,
          events: webhook.events.map(&:event),
          created_at: webhook.created_at
        }
      end

      def request_data(request)
        {
          uuid: request.uuid,
          url: request.url,
          event: request.event,
          status: request.error ? "error" : "success",
          error: request.error,
          attempts: request.attempts,
          created_at: request.created_at
        }
      end

    end
  end
end
