# frozen_string_literal: true

module API
  module V1
    class IPPoolRulesController < BaseController

      before_action :set_owner

      # GET /api/v1/organizations/:organization_id/ip_pool_rules
      # OR /api/v1/organizations/:organization_id/servers/:server_id/ip_pool_rules
      def index
        @rules = @owner.ip_pool_rules.order(:created_at)
        render_success(@rules.map { |r| rule_data(r) })
      end

      # GET /api/v1/.../ip_pool_rules/:id
      def show
        @rule = @owner.ip_pool_rules.find_by_uuid!(params[:id])
        render_success(rule_data(@rule))
      end

      # POST /api/v1/.../ip_pool_rules
      def create
        @rule = @owner.ip_pool_rules.build(rule_params)
        if @rule.save
          render_success(rule_data(@rule), status: 201)
        else
          render_error "RecordInvalid", message: @rule.errors.full_messages.join(", "), status: 422
        end
      end

      # PATCH /api/v1/.../ip_pool_rules/:id
      def update
        @rule = @owner.ip_pool_rules.find_by_uuid!(params[:id])
        if @rule.update(rule_params)
          render_success(rule_data(@rule))
        else
          render_error "RecordInvalid", message: @rule.errors.full_messages.join(", "), status: 422
        end
      end

      # DELETE /api/v1/.../ip_pool_rules/:id
      def destroy
        @rule = @owner.ip_pool_rules.find_by_uuid!(params[:id])
        @rule.destroy
        render_success({ message: "IP pool rule deleted successfully." })
      end

      private

      def set_owner
        @organization = current_user.organizations_scope.find_by_permalink!(params[:organization_id])
        if params[:server_id]
          @owner = @organization.servers.find_by_permalink!(params[:server_id])
        else
          @owner = @organization
        end
      end

      def rule_params
        params.require(:ip_pool_rule).permit(:ip_pool_id, :from_text, :to_text)
      end

      def rule_data(rule)
        {
          uuid: rule.uuid,
          ip_pool_id: rule.ip_pool_id,
          ip_pool_name: rule.ip_pool&.name,
          from_text: rule.from_text,
          to_text: rule.to_text,
          created_at: rule.created_at
        }
      end

    end
  end
end
