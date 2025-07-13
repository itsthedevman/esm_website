# frozen_string_literal: true

class UserAlias < ApplicationRecord
  before_validation(on: :create) { self.uuid ||= SecureRandom.uuid }

  attribute :uuid, :uuid
  attribute :user_id, :integer
  attribute :community_id, :integer
  attribute :server_id, :integer
  attribute :value, :string

  belongs_to :user
  belongs_to :community, optional: true
  belongs_to :server, optional: true

  validates :uuid, uniqueness: true, presence: true

  validates :value, uniqueness: {
    scope: [:user_id, :server_id],
    message: "This alias already exists for a server"
  }

  validates :value, uniqueness: {
    scope: [:user_id, :community_id],
    message: "This alias already exists for a server"
  }

  validates :value, length: {in: 1..64}

  def self.find_server_alias(value)
    eager_load(:server).where(value: value).where.not(server_id: nil).first
  end

  def self.find_community_alias(value)
    eager_load(:community).where(value: value).where.not(community_id: nil).first
  end

  def self.clientize
    all.map(&:clientize)
  end

  def clientize
    if community_id
      type = "community"
      target = community.clientize
    else
      type = "server"
      target = server.clientize
    end

    {id: uuid, type: type, target: target, value: value, state: "unchanged"}
  end
end
