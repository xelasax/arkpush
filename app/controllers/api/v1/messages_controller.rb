# frozen_string_literal: true

module Api
  module V1
    class MessagesController < BaseController

      before_action :set_organization
      before_action :set_server
      before_action :set_message, only: [:show, :activity, :deliveries, :retry, :cancel_hold]

      # GET /api/v1/organizations/:organization_id/servers/:server_id/messages
      def index
        options = { order: :timestamp, direction: "desc" }
        options[:where] = {}
        options[:where][:rcpt_to] = params[:to] if params[:to].present?
        options[:where][:mail_from] = params[:from] if params[:from].present?
        options[:where][:status] = params[:status] if params[:status].present?
        options[:where][:tag] = params[:tag] if params[:tag].present?
        options[:where][:id] = params[:msg_id] if params[:msg_id].present?

        @messages = @server.message_db.messages_with_pagination(params[:page], options)
        render_success(@messages.map { |m| message_summary_data(m) })
      end

      # GET /api/v1/organizations/:organization_id/servers/:server_id/messages/:id
      def show
        render_success(message_detail_data(@message))
      end

      # GET /api/v1/organizations/:organization_id/servers/:server_id/messages/:id/activity
      def activity
        render_success(@message.activity_entries)
      end

      # GET /api/v1/organizations/:organization_id/servers/:server_id/messages/:id/deliveries
      def deliveries
        render_success(@message.deliveries.map { |d| delivery_data(d) })
      end

      # POST /api/v1/organizations/:organization_id/servers/:server_id/messages/:id/retry
      def retry
        if @message.raw_message?
          @message.add_to_message_queue(manual: true)
          render_success({ message: "Message retry initiated successfully." })
        else
          render_error "NotAvailable", message: "Raw message data is no longer available for retry.", status: 410
        end
      end

      # POST /api/v1/organizations/:organization_id/servers/:server_id/messages/:id/cancel_hold
      def cancel_hold
        if @message.held?
          @message.cancel_hold
          render_success({ message: "Hold cancelled successfully." })
        else
          render_error "NotHeld", message: "This message is not on hold.", status: 400
        end
      end

      private

      def set_organization
        @organization = current_user.organizations_scope.find_by_permalink!(params[:organization_id])
      end

      def set_server
        @server = @organization.servers.find_by_permalink!(params[:server_id])
      end

      def set_message
        @message = @server.message_db.message(params[:id].to_i)
        render_not_found if @message.nil?
      end

      def message_summary_data(message)
        {
          id: message.id,
          token: message.token,
          to: message.rcpt_to,
          from: message.mail_from,
          subject: message.subject,
          status: message.status,
          timestamp: message.timestamp
        }
      end

      def message_detail_data(message)
        message_summary_data(message).merge({
          headers: message.headers,
          plain_body: message.plain_body,
          html_body: message.html_body,
          attachments: message.attachments.map { |a| { filename: a.filename, content_type: a.mime_type, size: a.body.size } }
        })
      end

      def delivery_data(delivery)
        {
          id: delivery.id,
          status: delivery.status,
          details: delivery.details,
          output: delivery.output,
          sent_with_ssl: delivery.sent_with_ssl,
          timestamp: delivery.timestamp
        }
      end

    end
  end
end
