# frozen_string_literal: true

module ESM
  class User < ApplicationRecord
    devise :omniauthable, :timeoutable, omniauth_providers: %i[discord steam]

    def self.from_omniauth(auth)
      user = where(discord_id: auth.uid).first_or_initialize

      user.update!(
        discord_username: auth.info.name,
        discord_avatar: auth.info.image,
        discord_access_token: auth.credentials.token,
        discord_refresh_token: auth.credentials.refresh_token
      )

      user
    end

    def timeout_in
      2.days
    end

    def server_communities
      @server_communities ||= ESM::Community.where(
        id: ESM.bot.user_community_ids(id, discord_server_ids, check_for_perms: true)
      ).order(:community_id)
    end

    def player_communities
      @player_communities ||= ESM::Community.where(
        id: ESM.bot.user_community_ids(id, discord_server_ids),
        player_mode_enabled: true
      ).order(:community_id)
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
        response = Discord.client(discord_access_token).user_guilds
        raise HTTP::ConnectionError unless response.status.success?

        response.body
          .to_s # JSON
          .to_a # Array<Hash>
          .key_map(:id)
      end
    end
  end
end
