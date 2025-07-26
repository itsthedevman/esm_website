# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  delegate :create_toast,
    :create_info_toast, :create_success_toast,
    :create_warn_toast, :create_error_toast,
    to: :helpers
end
