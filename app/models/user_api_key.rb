# frozen_string_literal: true

class UserAPIKey < ApplicationRecord

  belongs_to :user

  validates :key, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true

  before_validation :generate_key, on: :create

  def generate_key
    self.key = SecureRandom.alphanumeric(24) if key.blank?
  end

  def use
    update_column(:last_used_at, Time.now)
  end

end
