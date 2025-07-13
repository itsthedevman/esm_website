# frozen_string_literal: true

module ESM
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
end
