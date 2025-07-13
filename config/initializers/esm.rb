# frozen_string_literal: true

Rails.application.config.to_prepare do
  require "esm_ruby_core/models"

  Dir[Rails.root.join("app/models/esm/*.rb")].each { |f| require f }
end
