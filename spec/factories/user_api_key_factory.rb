# frozen_string_literal: true

FactoryBot.define do
  factory :user_api_key do
    user
    name { "Test API Key" }
  end
end
