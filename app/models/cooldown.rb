# frozen_string_literal: true

class Cooldown < ApplicationRecord
  attribute :command_name, :string
  attribute :community_id, :integer
  attribute :server_id, :integer
  attribute :user_id, :integer
  attribute :cooldown_quantity, :integer
  attribute :cooldown_type, :string
  attribute :cooldown_amount, :integer
  attribute :expires_at, :datetime
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  belongs_to :user
  belongs_to :server
  belongs_to :community
end
