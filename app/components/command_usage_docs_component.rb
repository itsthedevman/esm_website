# frozen_string_literal: true

class CommandUsageDocsComponent < ApplicationComponent
  include ArgumentFormatting

  def on_load(command:)
    @command = command
  end

  def call
    arguments =
      @command.arguments.join_map(" ") do |name, argument|
        semantic_class = argument_semantic_class(name, argument)

        <<~HTML
          <span class='arg #{semantic_class}'>#{argument["display_name"]}</span>
          <span class='text-muted'>:</span>
          <span class='arg #{semantic_class}'>&lt;#{argument["placeholder"]}&gt;</span>
        HTML
      end

    "#{@command.usage} #{arguments}".html_safe
  end
end
