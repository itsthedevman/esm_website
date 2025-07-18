# frozen_string_literal: true

class CommandExampleDocsComponent < ApplicationComponent
  include ArgumentFormatting

  def on_load(command:)
    @command = command
  end

  def call
    @command.examples.join_map do |example|
      arguments =
        (example["arguments"] || []).join_map(" ") do |name, value|
          # Try to find the semantic class for this argument name
          arg_def = @command.arguments[name]

          semantic_class =
            if arg_def
              argument_semantic_class(name, arg_def)
            else
              "content" # fallback for unknown arguments
            end

          format_argument(name, "arg #{semantic_class}", value:)
        end

      <<~HTML
        <div class="bg-black border-start border-primary border-3 p-3 mb-3 rounded-end">
          <div class="mb-2 small text-muted">#{Markdown.to_html(example["description"])}</div>
          <div class="font-monospace">
            <span class="text-primary fw-bold">#{@command.usage}</span> #{arguments}
          </div>
        </div>
      HTML
    end.html_safe
  end
end
