# frozen_string_literal: true

module ApplicationHelper
  def render_component(klass, **locals, &block)
    component = klass.new(current_user:, &block).tap do |component|
      component.on_load(**locals) if component.respond_to?(:on_load)
    end

    render(component)
  end
end
