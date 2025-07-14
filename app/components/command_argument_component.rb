# frozen_string_literal: true

class CommandArgumentComponent < ApplicationComponent
  include ArgumentFormatting
  
  def on_load(name, value = nil, aliases: [], only: nil)
    name = name.to_s
    color = CommandDetail.argument_colors[name]
    template = CommandDetail.all_arguments[name]
    generation_arty = [value, color, {placeholder_text: template["placeholder"], only: only}]

    capture do
      aliases.each do |name|
        concat generate_syntax(name, *generation_arty)
        concat ", " if aliases.size > 1
      end

      concat " and " if aliases.size > 0
      concat generate_syntax(name, *generation_arty)
    end
  end

  private

  def generate_syntax(name, value, color, opts = {})
    content_tag(:code, class: "command-syntax") do
      format_argument(name, value, color, **opts)
    end
  end
end
