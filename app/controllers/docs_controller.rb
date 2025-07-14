# frozen_string_literal: true

class DocsController < ApplicationController
  def commands
    all_commands = ESM::CommandDetail.all
      .order(command_category: :asc)
      .group_by(&:command_category)

    all_commands.each_value { |c| c.sort_by.dig(:command_category).sort }

    render locals: {all_commands:}
  end

  def getting_started
  end

  def player_setup
  end

  def server_setup
  end
end
