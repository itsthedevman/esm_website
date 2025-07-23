# frozen_string_literal: true

module ApplicationHelper
  def render_component(klass, **locals, &block)
    component = klass.new(current_user:, &block).tap do |component|
      component.on_load(**locals) if component.respond_to?(:on_load)
    end

    render(component)
  end

  def update_turbo_modal(&block)
    turbo_frame_tag "turbo_modal" do
      yield

      concat <<~HTML.html_safe
        <script>
          bootstrap.Modal.getOrCreateInstance(document.getElementById("turbo-modal")).show();
        </script>
      HTML
    end
  end

  def hide_turbo_modal
    turbo_stream.append("turbo_modal") do
      <<~HTML.html_safe
        <script>
          bootstrap.Modal.getOrCreateInstance(document.getElementById("turbo-modal")).hide();
        </script>
      HTML
    end
  end

  def link_to_tab(*, **args, &)
    link_to(*, args.merge(target: "_blank"), &)
  end
end
