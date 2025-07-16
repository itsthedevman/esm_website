# frozen_string_literal: true

class CommandComponent < ApplicationComponent
  def on_load(command:)
  end

  def usage_as_html
    arguments =
      command_arguments.join_map(" ") do |name, argument|
        semantic_class = argument_semantic_class(name, argument)

        "<span class='arg #{semantic_class}'>#{argument["display_name"]}</span><span class='text-muted'>:</span><span class='arg #{semantic_class}'>&lt;#{argument["placeholder"]}&gt;</span>"
      end

    "#{command_usage} #{arguments}".html_safe
  end

  def arguments_as_html
    arguments =
      command_arguments.join_map do |name, argument|
        semantic_class = argument_semantic_class(name, argument)

        <<~HTML
          <div class="mb-3 p-3 bg-black border border-secondary rounded">
            <div class="mb-2">
              <span class="arg #{semantic_class} fs-6">#{argument["display_name"]}</span>
            </div>
            <div class="text-light small">
              #{markdown_to_html(argument["description"])}
              #{"<br>#{markdown_to_html(argument["description_extra"])}" if argument["description_extra"].present?}
            </div>
          </div>
        HTML
      end

    arguments.html_safe
  end

  def example_as_html
    command_examples.join_map do |example|
      arguments =
        (example["arguments"] || []).join_map(" ") do |name, value|
          # Try to find the semantic class for this argument name
          arg_def = command_arguments[name]
          semantic_class = if arg_def
            argument_semantic_class(name, arg_def)
          else
            "content" # fallback for unknown arguments
          end

          "<span class='arg #{semantic_class}'>#{name}</span><span class='text-muted'>:</span><span class='arg #{semantic_class}'>#{value}</span>"
        end

      <<~HTML
        <div class="bg-black border-start border-primary border-3 p-3 mb-3 rounded-end">
          <div class="mb-2 small text-muted">#{markdown_to_html(example["description"])}</div>
          <div class="font-monospace">
            <span class="text-primary fw-bold">#{command_usage}</span> #{arguments}
          </div>
        </div>
      HTML
    end.html_safe
  end

  private

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
