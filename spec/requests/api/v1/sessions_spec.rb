# frozen_string_literal: true

require 'swagger_helper'

RSpec.describe 'Api::V1::Sessions', type: :request do
  path '/api/v1/sessions' do
    post 'Login and obtain API key' do
      tags 'Sessions'
      consumes 'application/json'
      parameter name: :credentials, in: :body, schema: {
        type: :object,
        properties: {
          email_address: { type: :string },
          password: { type: :string }
        },
        required: %w[email_address password]
      }

      response '200', 'login successful' do
        schema type: :object,
          properties: {
            status: { type: :string },
            data: {
              type: :object,
              properties: {
                api_key: { type: :string },
                user: { type: :object }
              }
            }
          }
        run_test!
      end

      response '401', 'invalid credentials' do
        run_test!
      end
    end

    delete 'Logout' do
      tags 'Sessions'
      security [bearerAuth: []]
      response '200', 'logout successful' do
        run_test!
      end
    end
  path '/api/v1/organizations' do
    get 'List organizations' do
      tags 'Organizations'
      security [bearerAuth: []]
      response '200', 'successful' do
        run_test!
      end
    end
  end
end
