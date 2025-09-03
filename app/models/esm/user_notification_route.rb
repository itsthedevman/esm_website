# frozen_string_literal: true

module ESM
  class UserNotificationRoute < ApplicationRecord
    # =============================================================================
    # INITIALIZE
    # =============================================================================

    # =============================================================================
    # DATA STRUCTURE
    # =============================================================================

    attr_writer :channel

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

    # This is under the assumption that these routes all belong to the same user
    def self.by_community_server_and_channel_for_user
      routes = includes(:user, :source_server, :destination_community)
        .load
        .group_by { |r| [r.destination_community_id, r.source_server_id, r.channel_id] }
        .filter_map do |(community_id, channel_id), routes|
          route = routes.first
          channel = route.channel
          next if channel.nil? # Ensures they have access to the channel

          [
            [route.destination_community, route.source_server, channel],
            routes.sort_by(&:notification_type)
          ]
        end

      routes.to_h
    end

    def self.by_user_channel_and_server
      routes = includes(:user, :source_server)
        .load
        .group_by { |r| [r.user_id, r.source_server_id, r.channel_id] }
        .map do |(user_id, channel_id), routes|
          route = routes.first
          channel = route.channel
          next if channel.nil? # Ensures they have access to the channel

          [
            [route.user, route.source_server, channel],
            routes.sort_by(&:notification_type)
          ]
        end

      routes.to_h
    end

    # =============================================================================
    # INSTANCE METHODS
    # =============================================================================

    def channel?
      !!channel
    end

    def channel
      @channel ||= ESM.bot.channel(
        channel_id,
        user_id:,
        community_id: destination_community_id
      ).to_istruct
    end

    def channel_name
      channel.name
    end
  end
end
