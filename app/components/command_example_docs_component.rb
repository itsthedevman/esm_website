# frozen_string_literal: true

class CommandExampleDocsComponent < ApplicationComponent
  include ArgumentFormatting

  def on_load(command:)
    @command = command
  end

  def call
    @command.examples.join_map do |example|
      <<~HTML
        <div class="bg-black border-start border-primary border-3 p-3 mb-3 rounded-end">
          <div class="mb-2 small text-muted">#{Markdown.to_html(example["description"])}</div>
          #{helpers.render_component CommandUsageDocsComponent, command: @command}
        </div>
      HTML
    end.html_safe
  end
end
