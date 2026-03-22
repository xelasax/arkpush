# frozen_string_literal: true

Rswag::Api.configure do |c|
  c.openapi_root = Rails.root.to_s + "/public/api-docs"
end
