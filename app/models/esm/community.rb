# frozen_string_literal: true

module ESM
  class Community < ApplicationRecord
    # =============================================================================
    # INITIALIZE
    # =============================================================================

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

    # =============================================================================
    # INSTANCE METHODS
    # =============================================================================

    def server_mode_enabled?
      !player_mode_enabled?
    end

    def modifiable_by?(user)
      ESM.bot.community_modifiable_by?(id, user.id)
    end

    def admin_channels
      @admin_channels ||= ESM.bot.community_channels(id)
    end

    def player_channels(user)
      @player_channels ||= ESM.bot.community_channels(id, user_id: user.id)
    end

    def roles
      @roles ||= ESM.bot.community_roles(id).map(&:to_struct)
    end

    def territory_admins
      validate_and_decorate_roles(territory_admin_ids)
    end

    def dashboard_admins
      validate_and_decorate_roles(dashboard_access_role_ids)
    end

    def change_id_to(new_id)
      # Adjust the server IDs
      Server.where(community_id: id).each do |server|
        old_id = server.server_id
        server.update(server_id: server.server_id.gsub("#{community_id}_", "#{new_id}_"))

        # Force the server to reconnect
        ESM.bot.reconnect_server(server.id, old_id)
      end

      update(community_id: new_id)
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
end
