# frozen_string_literal: true

class DocsController < ApplicationController
  def commands
    all_commands = ESM::CommandDetail.all
      .order(command_category: :asc)
      .group_by(&:command_category)
      .each_value do |commands|
        commands.map! { |c| Command.new(c) }.sort_by!(&:domain)
      end

    render locals: {all_commands:}
  end

  def getting_started
  end

  def player_setup
  end

  def server_setup
  end
end
