# frozen_string_literal: true

class Community < ApplicationRecord
  before_validation(on: :create) { self.public_id ||= SecureRandom.uuid }

  attribute :public_id, :uuid
  attribute :community_id, :string
  attribute :community_name, :text
  attribute :guild_id, :string
  attribute :logging_channel_id, :string
  attribute :log_reconnect_event, :boolean, default: false
  attribute :log_xm8_event, :boolean, default: true
  attribute :log_discord_log_event, :boolean, default: true
  attribute :log_error_event, :boolean, default: true
  attribute :player_mode_enabled, :boolean, default: true
  attribute :territory_admin_ids, :json, default: []
  attribute :dashboard_access_role_ids, :json, default: []
  attribute :command_prefix, :string, default: nil
  attribute :welcome_message_enabled, :boolean, default: true
  attribute :welcome_message, :string, default: ""
  attribute :allow_v2_servers, :boolean, default: false
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  has_many :command_configurations, dependent: :destroy
  has_many :cooldowns, dependent: :destroy
  has_many :id_defaults, class_name: "CommunityDefault", dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :servers, dependent: :destroy
  has_many :user_aliases, dependent: :nullify
  has_many :user_defaults, dependent: :nullify
  has_many :user_notification_routes, foreign_key: :destination_community_id, dependent: :destroy

  def self.find_by_community_id(id)
    order(:community_id).where("community_id ilike ?", id).first
  end

  def self.find_by_guild_id(id)
    order(:guild_id).where(guild_id: id).first
  end

  def self.find_by_server_id(id)
    # esm_malden -> esm
    community_id = id.match(/([^\s]+)_[^\s]+/i)[1]
    find_by_community_id(community_id)
  end

  def self.servers_by_community
    communities = Community.includes(:servers).joins(:servers).order(:community_id)

    communities.map do |community|
      servers = community.servers.order(:server_id).select(:server_id, :server_name)

      {
        name: "[#{community.community_id}] #{community.community_name}",
        servers: servers.map(&:clientize)
      }
    end
  end

  def modifiable_by?(user)
    ESM.community_modifiable_by?(id, user.id)
  end

  def admin_channels
    @admin_channels ||= ESM.community_channels(id)
  end

  def player_channels(user)
    @player_channels ||= ESM.community_channels(id, user_id: user.id)
  end

  def roles
    @roles ||= ESM.community_roles(id).map { |role| Struct.new(*role.keys).new(*role.values) }
  end

  def territory_admins
    validate_and_decorate_roles(territory_admin_ids)
  end

  def dashboard_admins
    validate_and_decorate_roles(dashboard_access_role_ids)
  end

  def discord_server
    @discord_server ||= ESM.bot.server(guild_id)
  end

  def change_id_to(new_id)
    # Adjust the server IDs
    Server.where(community_id: id).each do |server|
      old_id = server.server_id
      server.update(server_id: server.server_id.gsub("#{community_id}_", "#{new_id}_"))

      # Force the server to reconnect
      ESM.reconnect_server(server.id, old_id)
    end

    update(community_id: new_id)
  end

  def clientize
    {
      id: community_id,
      public_id: public_id,
      name: "[#{community_id}] #{community_name}"
    }
  end

  private

  def validate_and_decorate_roles(role_ids)
    return [] if role_ids.blank?

    role_ids.map do |id|
      role = roles.find { |r| r.id == id }
      next role_ids.delete(id) if role.nil?

      role
    end
  end
end
