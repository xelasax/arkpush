# frozen_string_literal: true

if defined?(Rswag::Api)
  Rswag::Api.configure do |c|
    c.openapi_root = Rails.root.to_s + "/public/api-docs"
  end
end
