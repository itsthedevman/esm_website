# frozen_string_literal: true

module ESM
  class UserAlias < ApplicationRecord
    def self.clientize
      all.map(&:clientize)
    end

    def clientize
      if community_id
        type = "community"
        target = community.clientize
      else
        type = "server"
        target = server.clientize
      end

      {id: uuid, type: type, target: target, value: value, state: "unchanged"}
    end
  end
end
