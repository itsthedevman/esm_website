# frozen_string_literal: true

module ESM
  class SteamAccount
    def token
      Rails.application.credentials.steam.token
    end
  end
end
