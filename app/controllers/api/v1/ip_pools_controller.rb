# frozen_string_literal: true

module Api
  module V1
    class IPPoolsController < BaseController

      before_action :admin_required

      # GET /api/v1/ip_pools
      def index
        @ip_pools = IPPool.order(:name)
        render_success(@ip_pools.map { |p| pool_data(p) })
      end

      # GET /api/v1/ip_pools/:id
      def show
        @ip_pool = IPPool.find_by_uuid!(params[:id])
        render_success(pool_data(@ip_pool))
      end

      # POST /api/v1/ip_pools
      def create
        @ip_pool = IPPool.new(pool_params)
        if @ip_pool.save
          render_success(pool_data(@ip_pool), status: 201)
        else
          render_error "RecordInvalid", message: @ip_pool.errors.full_messages.join(", "), status: 422
        end
      end

      # PATCH /api/v1/ip_pools/:id
      def update
        @ip_pool = IPPool.find_by_uuid!(params[:id])
        if @ip_pool.update(pool_params)
          render_success(pool_data(@ip_pool))
        else
          render_error "RecordInvalid", message: @ip_pool.errors.full_messages.join(", "), status: 422
        end
      end

      # DELETE /api/v1/ip_pools/:id
      def destroy
        @ip_pool = IPPool.find_by_uuid!(params[:id])
        @ip_pool.destroy
        render_success({ message: "IP Pool deleted successfully." })
      end

      private

      def pool_params
        params.require(:ip_pool).permit(:name, :uuid, :default)
      end

      def pool_data(pool)
        {
          name: pool.name,
          uuid: pool.uuid,
          default: pool.default,
          created_at: pool.created_at
        }
      end

    end
  end
end
