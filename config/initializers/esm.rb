# frozen_string_literal: true

Rails.application.config.to_prepare do
  require "esm_ruby_core/models"

  Rails.autoloaders.main.eager_load_dir(Rails.root.join("app/models"))
end
