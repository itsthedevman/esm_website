# frozen_string_literal: true

class DocsController < ApplicationController
  def commands
    all_commands = ESM::CommandDetail.all
      .order(command_category: :asc)
      .map { |c| Command.new(c) }
      .group_by { |c| [c.domain, c.category] }
      .each_value { |commands| commands.sort_by!(&:operation) }
      .sort_by { |k, v| k.first || :"" } # Sort by domain, pushes the root commands to the top

    render locals: {all_commands:}
  end

  def getting_started
  end

  def player_setup
  end

  def server_setup
  end
end
