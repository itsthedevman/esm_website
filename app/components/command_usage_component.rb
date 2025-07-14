# frozen_string_literal: true

class CommandUsageComponent < ApplicationComponent
  include ArgumentFormatting

  def on_load(command_name, arguments: {}, only: nil, skip_arguments: [])
    skip_arguments = skip_arguments.map(&:to_s)
    only = [:arguments, :placeholder] if only.nil?
    arguments = arguments.with_indifferent_access

    command = CommandDetail.all_commands[command_name]
    argument_html = []

    if only.include?(:arguments) && command.command_arguments.size > 0
      command.command_arguments.each do |name, template|
        next if skip_arguments.include?(name)

        display_name = template["display_name"]
        color = CommandDetail.argument_colors[name]

        value =
          if arguments.key?(name)
            arguments[name]
          elsif arguments.key?(display_name)
            arguments[display_name]
          end

        use_placeholders = only.include?(:placeholder)
        format_flags = {
          placeholder_text: (use_placeholders ? template["placeholder"] : nil),
          only: [
            ((value.present? || use_placeholders) ? :key : nil),
            (use_placeholders ? :placeholder : nil)
          ].compact
        }

        argument_html << format_argument(display_name, value, color, **format_flags)
      end
    end

    content_tag(:span, class: "esm-text-color-toast-blue command-syntax") do
      concat command.command_usage

      if argument_html.size > 0
        concat " "
        concat argument_html.join(" ").html_safe
      end
    end
  end
end
