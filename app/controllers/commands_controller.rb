# frozen_string_literal: true

class CommandsController < AuthenticatedController
  before_action :check_for_community_access!
  before_action :redirect_if_player_mode!

  def index
    commands_by_category = Command.all.values
      .sort_by(&:category)
      .select(&:modifiable?)
      .each { |command| command.preload_configuration(current_community) }
      .group_by(&:category)

    cooldown_types = ESM::CommandConfiguration::COOLDOWN_TYPES.map { |t| [t.humanize, t] }

    render locals: {commands_by_category:, cooldown_types:}
  end

  def update
    command = current_community.command_configurations.where(command_name: params[:name]).first
    command_details = command.details

    return render js: "Toaster.error('Configuration for <code>/#{params[:name]}</code> for your community was not found<br><span class='esm-text-color-red'>Please log out and log back in again</span><br>If this error persists, please join our Discord and let us know.');" if command.nil?

    # Default these. If they are empty (or unchecked), the param is nil
    params[:allowlisted_role_ids] ||= []
    params[:enabled] ||= false
    params[:notify_when_disabled] ||= false

    # Same goes for whitelist and allowed
    # Only modify these if the command is enabled though.
    if params[:enabled]
      params[:allowed_in_text_channels] ||= false
      params[:allowlist_enabled] ||= false
    else
      # If the command is not enabled, remove these from the params
      params.delete(:allowed_in_text_channels)
      params.delete(:allowlist_enabled)
    end

    if command.update(command_params)
      render js: "Toaster.success('<code>#{command_details.command_usage}</code> has been updated');"
    else
      render js: "Toaster.error('Failed to update.<br><span class='esm-text-color-red'>Please log out and log back in again</span><br>If this error persists, please join our Discord and let us know.');"
    end
  end

  private

  def command_params
    params.permit(:enabled, :notify_when_disabled, :allowed_in_text_channels, :cooldown_quantity, :cooldown_type, :allowlist_enabled, allowlisted_role_ids: [])
  end
end
