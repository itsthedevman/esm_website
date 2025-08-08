# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Exceptions

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  delegate :dom_id,
    :create_toast,
    :create_info_toast, :create_success_toast,
    :create_warn_toast, :create_error_toast,
    :hide_modal,
    to: :helpers

  rescue_from NotFoundError, with: :render_not_found
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  def render_not_found(exception = nil)
    respond_to do |format|
      format.html { render template: "errors/not_found_404", status: :not_found }

      format.json { render json: {error: "Not found"}, status: :not_found }

      format.turbo_stream do
        render turbo_stream: create_error_toast("The request item was not found"),
          status: :not_found
      end
    end
  end

  def not_found!
    raise NotFoundError.new
  end
end
