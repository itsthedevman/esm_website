# frozen_string_literal: true

class Bot
  def self.instance
    DRb::DRbObject.new_with_uri("druby://localhost:#{ENV["API_PORT"]}")
  end

  # Returns the channels for a guild that the bot has send permissions for
  def self.community_channels(community_id, user_id: nil)
    instance.community_channels(id: community_id, user_id: user_id) || []
  end

  def self.community_modifiable_by?(community_id, user_id)
    instance.community_modifiable_by?(id: community_id, user_id: user_id) || []
  end

  def self.community_roles(community_id)
    instance.community_roles(id: community_id) || []
  end

  def self.community_users(community_id)
    instance.community_users(id: community_id) || []
  end

  def self.user_community_ids(user_id, guild_ids, check_for_perms: false)
    instance.user_communities(id: user_id, guild_ids:, check_for_perms:) || []
  end

  def self.channel(channel_id, **filters)
    instance.channel(**filters.merge(id: channel_id))
  end

  def self.send_message(channel_id:, message:)
    instance.channel_send(id: channel_id, message: message.to_json)
  end

  def self.update_server(id)
    instance.servers_update(id: id)
  end

  def self.reconnect_server(id, old_id)
    instance.servers_reconnect(id: id, old_id: old_id)
  end

  def self.accept_request(id)
    instance.requests_accept(id: id)
  end

  def self.decline_request(id)
    instance.requests_decline(id: id)
  end

  def self.delete_community(community_id, user_id)
    instance.community_delete(id: community_id, user_id: user_id) || false
  end
end

module EMBED
  TITLE_LENGTH_MAX = 256
  DESCRIPTION_LENGTH_MAX = 2048
  FIELD_NAME_LENGTH_MAX = 256
  FIELD_VALUE_LENGTH_MAX = 1024

  # Converts the constants into a key, value hash
  def self.to_h
    constant_hash = {}

    constants(false).each do |constant|
      constant_hash[constant] = const_get(constant)
    end

    constant_hash
  end
end
