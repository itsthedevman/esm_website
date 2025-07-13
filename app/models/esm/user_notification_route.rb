# frozen_string_literal: true

module ESM
  class UserNotificationRoute < ApplicationRecord
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

        channel = Bot.channel(channel_id, community_id: destination_community.id, user_id: user.id)
        next if channel.nil? # Ensures the user has access

        {
          user: user.clientize,
          channel: {id: channel[:id], name: channel[:name]},
          servers: servers,
          community: destination_community.clientize
        }
      end
    end
  end
end
