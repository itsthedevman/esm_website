# frozen_string_literal: true

module ESM
  class User < ApplicationRecord
    # =============================================================================
    # INITIALIZE
    # =============================================================================

    devise :omniauthable, :timeoutable, omniauth_providers: %i[discord steam]

    # =============================================================================
    # DATA STRUCTURE
    # =============================================================================

    # =============================================================================
    # ASSOCIATIONS
    # =============================================================================

    # =============================================================================
    # VALIDATIONS
    # =============================================================================

    # =============================================================================
    # CALLBACKS
    # =============================================================================

    # =============================================================================
    # SCOPES
    # =============================================================================

    # =============================================================================
    # CLASS METHODS
    # =============================================================================

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

    # =============================================================================
    # INSTANCE METHODS
    # =============================================================================

    def timeout_in
      2.days
    end

    def community_permissions
      @community_permissions ||= ESM.bot.user_community_permissions(id, discord_server_ids)
    end

    def admin_community_ids
      community_permissions.select { |c| c[:modifiable] }.key_map(:id)
    end

    def player_community_ids
      community_permissions.key_map(:id)
    end

    def server_communities
      @server_communities ||= ESM::Community.all
        .includes(:servers)
        .order("UPPER(community_id)")
        .where(id: admin_community_ids)
    end

    def player_communities
      @player_communities ||= ESM::Community.all
        .includes(:servers)
        .order("UPPER(community_id)")
        .where(id: player_community_ids, player_mode_enabled: true)
    end

    def avatar_url
      if discord_avatar.blank? || discord_avatar.end_with?("#{discord_id}/")
        ActionController::Base.helpers.image_url("default_discord_avatar.png")
      else
        discord_avatar
      end
    end

    def discord_server_ids
      @discord_server_ids ||= Rails.cache.fetch(
        "user:#{id}:discord_server_ids",
        expires_in: 5.minutes
      ) do
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
