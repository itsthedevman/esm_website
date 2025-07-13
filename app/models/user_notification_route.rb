# frozen_string_literal: true

class UserNotificationRoute < ApplicationRecord
  attribute :uuid, :uuid
  attribute :user_id, :integer
  attribute :source_server_id, :integer # nil means "any server"
  attribute :destination_community_id, :integer
  attribute :channel_id, :string
  attribute :notification_type, :string
  attribute :enabled, :boolean, default: true
  attribute :user_accepted, :boolean, default: false
  attribute :community_accepted, :boolean, default: false
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  belongs_to :user
  belongs_to :destination_community, class_name: "Community"
  belongs_to :source_server, class_name: "Server", optional: true

  validates :uuid, :user_id, :destination_community_id, :channel_id, presence: true
  validates :notification_type, presence: true, uniqueness: {scope: %i[user_id destination_community_id source_server_id channel_id]}

  before_create :create_uuid

  scope :accepted, -> { where(user_accepted: true, community_accepted: true) }
  scope :pending_community_acceptance, -> { where(user_accepted: true, community_accepted: false) }
  scope :pending_user_acceptance, -> { where(user_accepted: false, community_accepted: true) }

  TYPES = %w[
    custom
    base-raid
    flag-stolen
    flag-restored
    flag-steal-started
    protection-money-due
    protection-money-paid
    grind-started
    hack-started
    charge-plant-started
    marxet-item-sold
  ].freeze

  TYPE_PRESETS = {
    raids: %w[
      base-raid
      flag-stolen
      flag-restored
      flag-steal-started
      grind-started
      hack-started
      charge-plant-started
    ].freeze,
    payments: %w[
      protection-money-due
      protection-money-paid
    ].freeze
  }.freeze

  def self.by_channel_server_and_user
    all.includes(:user, :source_server, :destination_community).sort_by { |r| r.user.discord_username }.group_by { |r| [r.user, r.destination_community, r.channel_id] }
  end

  def self.clientize
    by_channel_server_and_user.filter_map do |(user, destination_community, channel_id), routes|
      servers = routes.group_by(&:source_server).map do |source_server, server_routes|
        types = server_routes.sort_by(&:notification_type).map do |r|
          {
            id: r.uuid,
            name: r.notification_type.titleize,
            enabled: r.enabled?,
            user_accepted: r.user_accepted?,
            community_accepted: r.community_accepted?,
            editable: r.user_accepted? && r.community_accepted?
          }
        end

        {id: source_server&.server_id, name: source_server&.server_name || "Any server", types: types}
      end

      channel = ESM.channel(channel_id, community_id: destination_community.id, user_id: user.id)
      next if channel.nil? # Ensures the user has access

      {
        user: user.clientize,
        channel: {id: channel[:id], name: channel[:name]},
        servers: servers,
        community: destination_community.clientize
      }
    end
  end

  private

  def create_uuid
    self.uuid = SecureRandom.uuid
  end
end
