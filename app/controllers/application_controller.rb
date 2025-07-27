# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Exceptions

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  delegate :create_toast,
    :create_info_toast, :create_success_toast,
    :create_warn_toast, :create_error_toast,
    to: :helpers

  rescue_from NotFoundError, with: :render_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def render_not_found(exception = nil)
    respond_to do |format|
      format.html do
        render partial: "errors/404", status: :not_found, layout: "application"
      end

      format.json { render json: {error: "Not found"}, status: :not_found }
    end
  end

  def not_found!
    raise NotFoundError.new
  end
end
