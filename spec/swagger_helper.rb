# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('public', 'api-docs').to_s
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Postcontrol API V1',
        version: 'v1'
      },
      paths: {},
      servers: [
        {
          url: '{protocol}://{host}',
          variables: {
            protocol: { default: 'https' },
            host: { default: 'postal.example.com' }
          }
        }
      ]
    }
  }
  config.openapi_format = :yaml
end
