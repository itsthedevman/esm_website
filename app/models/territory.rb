# frozen_string_literal: true

class Territory < ApplicationRecord
  attribute :server_id, :integer
  attribute :territory_level, :integer
  attribute :territory_purchase_price, :integer
  attribute :territory_radius, :integer
  attribute :territory_object_count, :integer
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  belongs_to :server
end
