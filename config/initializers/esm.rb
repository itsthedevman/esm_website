# frozen_string_literal: true

Rails.application.config.to_prepare do
  # Explicitly require core models
  core_path = Pathname.new(File.expand_path("../../../", __dir__))
    .join("esm_ruby_core/lib")

  Dir[core_path.join("esm/models/*.rb")].sort.each do |file|
    load file
  end

  # Now load website extensions
  Dir[Rails.root.join("app/models/esm/**/*.rb")].sort.each do |file|
    load file
  end
end
