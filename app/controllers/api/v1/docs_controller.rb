# frozen_string_literal: true

module Api
  module V1
    class DocsController < ApplicationController

      layout false # Use a clean layout for the API documentation

      def index
        # This will render the index.html.erb view
      end

    end
  end
end
