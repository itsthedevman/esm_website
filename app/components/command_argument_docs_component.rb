# frozen_string_literal: true

class CommandArgumentDocsComponent < ApplicationComponent
  include ArgumentFormatting

  def on_load(command:)
    @command = command
  end

  def call
    arguments =
      @command.arguments.join_map do |name, argument|
        semantic_class = argument_semantic_class(name, argument)

        <<~HTML
          <div class="mb-3 p-3 bg-black border border-secondary rounded">
            <div class="mb-2">
              <span class="arg #{semantic_class} fs-6">#{argument["display_name"]}</span>
            </div>
            <div class="text-light small">
              #{Markdown.to_html(argument["description"])}
              #{"<br>#{Markdown.to_html(argument["description_extra"])}" if argument["description_extra"].present?}
            </div>
          </div>
        HTML
      end

    arguments.html_safe
  end
end
