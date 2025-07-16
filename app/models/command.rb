# frozen_string_literal: true

class Command
  attr_reader :domain, :scope, :action

  attr_predicate :admin

  def initialize(command_details)
    @details = command_details

    parse_command_usage

    @admin = scope == :admin
  end

  private

  def parse_command_usage
    parts = @details.command_usage.split(" ")

    # Split the command usage into parts using: /[domain] ?[scope] [action]
    @domain = parts.first.delete_prefix("/").to_sym
    @scope = nil
    @action = parts.third&.to_sym

    if @action.present?
      @scope = parts.second&.to_sym
    else
      @action = parts.second&.to_sym
    end
  end
end
