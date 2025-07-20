# frozen_string_literal: true

class Discord
  include Singleton

  def self.channels(guild_id)
    instance.get("/guilds/#{guild_id}/channels")
  end

  def initialize
    token = Rails.application.credentials.discord[:token]
    @client = HTTP.auth("Bot #{token}")
    @base_url = "https://discord.com/api/v10"
  end

  def get(url)
    @client.get("#{@base_url}/#{url}")
  end
end
