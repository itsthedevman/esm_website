# frozen_string_literal: true

class Log < ApplicationRecord
  attribute :uuid, :uuid
  attribute :server_id, :integer
  attribute :search_text, :text
  attribute :requestors_user_id, :string
  attribute :expires_at, :datetime
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  belongs_to :user, class_name: "User", foreign_key: "requestors_user_id"
  belongs_to :server
  has_many :log_entries, dependent: :destroy
end
