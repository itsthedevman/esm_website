# frozen_string_literal: true

module TurboHelper
  def update_turbo_modal(&block)
    turbo_frame_tag "turbo_modal" do
      yield

      concat content_tag(:div, nil, data: {trigger: "modal:show:#turbo-modal"})
    end
  end

  def hide_turbo_modal
    hide_modal("#turbo-modal")
  end

  def hide_modal(selector)
    turbo_stream.append("main-container") do
      content_tag(:div, nil, data: {trigger: "modal:hide:#{selector}"})
    end
  end
end
