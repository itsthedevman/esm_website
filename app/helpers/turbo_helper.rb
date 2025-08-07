# frozen_string_literal: true

module TurboHelper
  def update_turbo_modal(&block)
    turbo_frame_tag "turbo_modal" do
      yield

      concat <<~HTML.html_safe
        <script>showTurboModal();</script>
      HTML
    end
  end

  def hide_turbo_modal
    turbo_stream.append("turbo_modal") do
      <<~HTML.html_safe
        <script>hideTurboModal();</script>
      HTML
    end
  end
end
