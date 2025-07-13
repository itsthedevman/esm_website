# frozen_string_literal: true

class UserDefault < ApplicationRecord
  attribute :user_id, :integer
  attribute :community_id, :integer
  attribute :server_id, :integer

  belongs_to :user
  belongs_to :community, optional: true
  belongs_to :server, optional: true
end
