# frozen_string_literal: true

module ESM
  class CommandDetail < ApplicationRecord
    COLORS = %i[green yellow orange purple pink burnt-orange lavender steel-green sage].freeze

    attr_reader :configuration

    def self.all_arguments
      Rails.cache.fetch("all-arguments", expires_in: 1.hour) do
        all.pluck(:command_arguments)
          .flat_map(&:values)
          .uniq { |a| a["name"] }
          .each_with_object({}) do |template, hash|
          hash[template["name"]] ||= template
          hash[template["display_name"]] ||= template
        end
      end
    end

    def self.argument_colors
      Rails.cache.fetch("argument-colors", expires_in: 1.hour) do
        colors = (COLORS.shuffle + COLORS.shuffle) # I have 10 colors and 16 unique arguments

        all.pluck(:command_arguments)
          .flat_map(&:values)
          .uniq { |a| a["name"] }
          .shuffle
          .each_with_object({}) do |template, hash|
            color = "color-#{colors.pop}"

            hash[template["name"]] = color
            hash[template["display_name"]] = color
          end
      end
    end

    def self.all_commands
      commands =
        Rails.cache.fetch("all-commands", expires_in: 1.hour) do
          all.each_with_object({}) { |command, hash| hash[command.command_name] = command.attributes }
        end

      commands.with_indifferent_access
        .transform_values! { |c| new(**c) }
    end

    def usage_as_html
      arguments =
        command_arguments.format(join_with: " ") do |name, argument|
          argument_color = self.class.argument_colors[name]

          "<span class='#{argument_color}'>#{argument["display_name"]}</span><span class='uk-text-muted'>:</span><span class='#{argument_color}'>&lt;#{argument["placeholder"]}&gt;</span>"
        end

      "#{command_usage} #{arguments}".html_safe
    end

    def description_as_html
      markdown_to_html(command_description).html_safe
    end

    def arguments_as_html
      arguments =
        command_arguments.format do |name, argument|
          argument_color = self.class.argument_colors[name]

          <<~HTML
            <dt>
              <pre class="uk-margin-remove-bottom"><strong class="#{argument_color}">#{name}</strong><span class='uk-text-muted'>:</span></pre>
            </dt>
            <dd>
              #{markdown_to_html(argument["description"])}
              <br>
              #{markdown_to_html(argument["description_extra"] || "")}
            </dd>
          HTML
        end

      <<~HTML.html_safe
        <dl class="uk-description-list">
          #{arguments}
        </dl>
      HTML
    end

    def example_as_html
      command_examples.format do |example|
        arguments =
          (example["arguments"] || []).format(join_with: " ") do |name, value|
            argument_color = self.class.argument_colors[name]

            "<span class='#{argument_color}'>#{name}</span><span class='uk-text-muted'>:</span><span class='#{argument_color}'>#{value}</span>"
          end

        <<~HTML
          <div class="uk-margin-small-bottom" uk-grid>
            <div>
              <div class="command-syntax uk-width-auto">
                <code><span class="esm-text-color-toast-blue">#{command_usage}</span> #{arguments}</code>
              </div>
            </div>
          </div>

          <p class="uk-margin-remove-top">#{markdown_to_html(example["description"])}</p>
        HTML
      end.html_safe
    end

    private

    def markdown_to_html(markdown)
      Kramdown::Document.new(markdown.gsub("\n", "<br>"))
        .to_html
        .gsub(/<p>|<\/p>/, "") # Remove the <p> tag that Kramdown adds
    end
  end
end
