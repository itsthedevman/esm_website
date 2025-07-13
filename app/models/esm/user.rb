# frozen_string_literal: true

module ESM
  class User < ApplicationRecord
    devise :omniauthable, :timeoutable, omniauth_providers: %i[discord steam]

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

    def clientize
      {
        id: discord_id,
        public_id: discord_id,
        name: username,
        avatar: avatar_url,
        steam_uid: steam_uid
      }
    end

    def timeout_in
      2.days
    end

    def admin_communities
      @admin_communities ||= Community.where(
        id: Bot.user_community_ids(id, discord_server_ids, check_for_perms: true)
      ).sort_by(&:community_id)
    end

    def player_communities
      @player_communities ||= Community.where(
        id: Bot.user_community_ids(id, discord_server_ids),
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
  end
end
