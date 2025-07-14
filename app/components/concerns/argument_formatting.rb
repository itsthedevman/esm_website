# frozen_string_literal: true

module ArgumentFormatting
  def format_argument(name, value, color, placeholder_text: "", only: nil)
    only = [:key, :placeholder] if only.nil?

    value =
      if value.present?
        content_tag(:span, value, class: color)
      elsif only.include?(:placeholder) && placeholder_text.present?
        "&lt;#{placeholder_text}&gt;".html_safe
      end

    show_key = only.include?(:key)
    capture do
      concat content_tag(:span, name, class: color) if show_key
      concat content_tag(:span, ":", class: "text-secondary") if show_key && value
      concat content_tag(:span, value, class: color) if value
    end
  end
end
