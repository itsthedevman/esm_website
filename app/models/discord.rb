# frozen_string_literal: true

class Discord
  include HTTParty

  base_uri "discord.com/api/v10"
  debug_output

  OPTIONS = {headers: {Authorization: "Bot #{ENV["DISCORD_TOKEN"]}"}}.freeze

  def self.channels(guild_id)
    get("/guilds/#{guild_id}/channels", **OPTIONS)
  end
end
