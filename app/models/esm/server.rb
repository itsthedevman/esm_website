# frozen_string_literal: true

module ESM
  class Server < ApplicationRecord
    def recently_created?(time: 30.seconds.ago)
      created_at.between?(time, Time.current)
    end

    def connected?
      true
    end
  end
end
