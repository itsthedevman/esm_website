# frozen_string_literal: true

module ApplicationHelper
  def render_component(klass, **locals, &block)
    render klass.new(current_user:, &block).tap do |component|
      component.call(**locals) if component.respond_to?(:call)
    end
  end
end
