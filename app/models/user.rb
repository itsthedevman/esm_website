# frozen_string_literal: true

class User < ApplicationRecord
  before_save :insert_steam_uid_history
  after_create :create_user_steam_data
  after_create :create_id_defaults

  devise :omniauthable, :timeoutable, omniauth_providers: %i[discord steam]

  attribute :discord_id, :string
  attribute :discord_username, :string
  attribute :discord_avatar, :text, default: nil
  attribute :discord_access_token, :string, default: nil
  attribute :discord_refresh_token, :string, default: nil
  attribute :steam_uid, :string, default: nil
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  has_many :cooldowns, dependent: :nullify
  has_many :id_aliases, class_name: "UserAlias", dependent: :destroy
  has_one :id_defaults, class_name: "UserDefault", dependent: :destroy
  has_many :logs, class_name: "Log", foreign_key: "requestors_user_id", dependent: :destroy
  has_many :outbound_requests, foreign_key: :requestor_user_id, class_name: "Request", dependent: :destroy
  has_many :inbound_requests, foreign_key: :requestee_user_id, class_name: "Request", dependent: :destroy
  has_many :user_gamble_stats, dependent: :destroy
  has_many :user_notification_preferences, dependent: :destroy
  has_many :user_notification_routes, dependent: :destroy
  has_one :user_steam_data, dependent: :destroy
  has_many :user_steam_uid_history, dependent: :nullify

  module Bryan
    ID = "137709767954137088"
  end

  def self.find_by_steam_uid(uid)
    order(:steam_uid).where(steam_uid: uid).first
  end

  def self.find_by_discord_id(id)
    id = id.to_s unless id.is_a?(String)
    order(:discord_id).where(discord_id: id).first
  end

  def self.from_omniauth(auth)
    user = User.where(discord_id: auth.uid).first_or_initialize

    user.update!(
      discord_username: auth.info.name,
      discord_avatar: auth.info.image,
      discord_access_token: auth.credentials.token,
      discord_refresh_token: auth.credentials.refresh_token
    )

    user
  end

  def to_error_h
    {
      id: id,
      discord_username: discord_username,
      steam_uid: steam_uid
    }
  end

  def steam_data
    @steam_data ||= lambda do
      # If the data is stale, it will automatically refresh
      user_steam_data.refresh
      user_steam_data
    end.call
  end

  def clientize
    {
      id: discord_id,
      public_id: discord_id,
      name: user_name,
      avatar: avatar_url,
      steam_uid: steam_uid
    }
  end

  def registered?
    steam_uid.present?
  end

  def deregister!
    update!(steam_uid: nil)
    user_steam_data.update!(
      username: nil,
      avatar: nil,
      profile_url: nil,
      profile_visibility: nil,
      profile_created_at: nil,
      community_banned: nil,
      vac_banned: nil,
      number_of_vac_bans: nil,
      days_since_last_ban: nil,
      updated_at: 30.minutes.ago
    )
  end

  def developer?
    [Bryan::ID].include?(discord_id)
  end

  def timeout_in
    2.days
  end

  def mention
    "<@#{discord_id}>"
  end

  def user_name
    discord_username
  end

  def admin_communities
    @admin_communities ||= Community.where(
      id: ESM.user_community_ids(id, discord_server_ids, check_for_perms: true)
    ).sort_by(&:community_id)
  end

  def player_communities
    @player_communities ||= Community.where(
      id: ESM.user_community_ids(id, discord_server_ids),
      player_mode_enabled: true
    ).sort_by(&:community_id)
  end

  def avatar_url
    if discord_avatar.blank? || discord_avatar.end_with?("#{discord_id}/")
      ActionController::Base.helpers.image_url("default_discord_avatar.png")
    else
      discord_avatar
    end
  end

  def discord_server_ids
    @discord_server_ids ||= begin
      response = HTTParty.get("http://discordapp.com/api/users/@me/guilds", headers: {Authorization: "Bearer #{discord_access_token}"})
      return [] unless response.ok?

      response.parsed_response.map { |s| s["id"] }
    end
  end

  private

  def insert_steam_uid_history
    return unless changes.key?(:steam_uid)

    user_steam_uid_history.create!(
      previous_steam_uid: changes[:steam_uid].first,
      new_steam_uid: changes[:steam_uid].second
    )
  end
end
