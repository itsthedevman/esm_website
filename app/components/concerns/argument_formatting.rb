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

  def argument_semantic_class(name, argument)
    display_name = argument["display_name"] || name

    # Identifiers - things that reference entities in the system
    return "identifier" if %w[
      server_id community_id territory_id
      on for from to in
    ].include?(display_name)

    # Targets - users/players to act upon
    return "target" if %w[
      target whom who
    ].include?(display_name)

    # Content - values, messages, data to process
    return "content" if %w[
      amount value money poptabs respect
      message reason description execute
      code_to_execute search_text
    ].include?(display_name)

    # Options - flags, modes, settings
    return "option" if %w[
      action type mode order_by broadcast_to
      cooldown_type notification_type
    ].include?(display_name)

    # Default fallback - most arguments are content-like
    "content"
  end
end
