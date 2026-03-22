# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Organizations', type: :request do
  let(:user) { create(:user) }
  let(:user_api_key) { create(:user_api_key, user: user) }
  let(:Authorization) { "Bearer #{user_api_key.key}" }

  path '/api/v1/organizations' do
    get 'List organizations' do
      tags 'Organizations'
      security [bearerAuth: []]
      response '200', 'successful' do
        schema type: :object,
          properties: {
            status: { type: :string },
            data: {
              type: :array,
              items: { type: :object }
            }
          }
        run_test!
      end
    end

    post 'Create organization' do
      tags 'Organizations'
      security [bearerAuth: []]
      consumes 'application/json'
      parameter name: :organization, in: :body, schema: {
        type: :object,
        properties: {
          organization: {
            type: :object,
            properties: {
              name: { type: :string },
              permalink: { type: :string }
            },
            required: %w[name permalink]
          }
        }
      }

      let(:organization) { { organization: { name: 'Test Org', permalink: 'test-org' } } }
      response '201', 'organization created' do
        run_test!
      end
    end
  end

  path '/api/v1/organizations/{id}/servers' do
    parameter name: :id, in: :path, type: :string
    let(:id) { 'test-org' }

    get 'List servers' do
      tags 'Servers'
      security [bearerAuth: []]
      response '200', 'successful' do
        run_test!
      end
    end

    post 'Create server' do
      tags 'Servers'
      security [bearerAuth: []]
      consumes 'application/json'
      parameter name: :server, in: :body, schema: {
        type: :object,
        properties: {
          server: {
            type: :object,
            properties: {
              name: { type: :string },
              permalink: { type: :string }
            }
          }
        }
      }

      let(:server) { { server: { name: 'Test Server', permalink: 'test-server' } } }
      response '201', 'server created' do
        run_test!
      end
    end
  end
end
