# frozen_string_literal: true

class ServersController < AuthenticatedController
  before_action :check_for_community_access!

  def show
    redirect_to edit_community_server_path(current_community, params[:server_id])
  end

  def new
    existing_server_ids = current_community.servers
      .pluck(:server_id)
      .map { |id| id.split("_").second }
      .sort_by
      .insensitive
      .sort

    render locals: {existing_server_ids:}
  end

  def edit
    server = current_community.servers.find_by(public_id: params[:server_id])

    render locals: {server:}
  end

  def key
    server = find_server
    not_found! if server.nil?

    send_data(server.server_key, filename: "esm.key")
  end

  def server_token
    server = find_server
    not_found! if server.nil?

    send_data(server.token.to_json, filename: "esm.key")
  end

  def server_config
    server = find_server
    not_found! if server.nil?

    config = render_to_string(
      template: "servers/config.yml.erb",
      locals: {settings: server.server_setting.attributes},
      layout: false
    )

    send_data(config, filename: "config.yml")
  end

  def create
    server_params = permit_create_params

    server = current_community.servers.create!(server_params)

    flash[:success] = "Server #{server.server_id} has been created"
    redirect_to edit_community_server_path(current_community, server)
  end

  def update
    # @server = current_community.servers.where(public_id: params[:id]).first
    # redirect_to community_servers_path(current_community.public_id) if @server.nil?

    # server_attributes, mod_attributes, reward_attributes, setting_attributes = sanitize_params

    # # Update the actual server
    # @server.update!(server_attributes)

    # # Update mods for this server
    # if mod_attributes.present?
    #   # Delete all of the mods
    #   @server.server_mods.destroy_all

    #   # And recreate them
    #   mod_attributes.each do |mod|
    #     @server.server_mods.create!(mod)
    #   end
    # end

    # # Update the server reward for this server
    # @server.server_rewards.default.update!(reward_attributes)

    # # Create the settings
    # @server.server_setting.update!(setting_attributes)

    # if @server.persisted?
    #   ESM.update_server(@server.id) if @server.server_setting.server_needs_restarted?

    #   flash[:success] = "Server #{@server.server_id} has been updated"

    #   opts = {}
    #   opts[:config_changed] = true if @server.server_setting.config_changed?

    #   redirect_to edit_community_server_path(current_community.public_id, @server.public_id, **opts)
    # else
    #   Rails.logger.error do
    #     "Failed to update server ID #{@server.id}. Error: #{@server.errors.full_messages.to_sentence}"
    #   end

    #   redirect_to edit_community_server_path(current_community.public_id, @server.public_id),
    #     alert: <<~HTML
    #       Failed to create server
    #       <br>
    #       <span class="esm-text-color-red">Please log out and log back in again</span>
    #       <br>
    #       If this error persists, please join our Discord and let us know.
    #     HTML
    # end
  end

  def destroy
    server = find_server
    not_found! if server.nil?

    if server.destroy
      flash[:success] = "#{server.server_id} has been deleted"
      redirect_to community_servers_path(current_community)
    else
      redirect_to edit_community_server_path(current_community, server), alert: "Failed to delete server<br><span class='esm-text-color-red'>Please log out and log back in again</span><br>If this error persists, please join our Discord and let us know."
    end
  end

  def enable_v2
    server = find_server
    not_found! if server.nil?

    server.update!(ui_version: "2.0.0")

    render turbo_stream: turbo_stream.refresh(request_id: nil)
  end

  def disable_v2
    server = find_server
    not_found! if server.nil?

    server.update!(ui_version: "1.0.0")

    render turbo_stream: turbo_stream.refresh(request_id: nil)
  end

  private

  def find_server
    current_community.servers.find_by(public_id: params[:server_id])
  end

  def permit_create_params
    permitted_params = params.require(:server).permit(
      :server_id, :server_ip, :server_port,
      :server_visibility, :ui_version
    )

    sanitize_params(permitted_params)
  end

  def permit_update_params
    permitted_params = params.require(:server).permit(
      :server_id, :server_ip, :server_port,
      :server_visibility, :ui_version,
      server_setting: {}, server_reward: {}
    )

    sanitize_params(permitted_params)
  end

  def sanitize_params(permitted_params)
    permitted_params[:server_id] =
      "#{current_community.community_id}_#{permitted_params[:server_id]}"

    permitted_params[:server_visibility] =
      if permitted_params[:server_visibility] == "0"
        :private
      else
        :public
      end

    version = permitted_params.delete(:ui_version)
    permitted_params[:ui_version] = "#{version}.0.0" if [1, 2].include?(version)

    permitted_params
  end
end

#  server_attributes = server_params.reject { |k, _v| k.in?(%w[server_mods server_setting server_reward]) }
#     mod_attributes = JSON.parse(server_params[:server_mods])

#     if mod_attributes.present?
#       mod_attributes.each do |mod|
#         mod.except!("_previous_name")
#         mod["mod_required"] || false
#       end
#     end

#     reward_attributes = server_params[:server_reward]
#     setting_attributes = server_params[:server_setting]

#     # Append the community ID to the server ID
#     server_attributes[:server_id] = "#{current_community.community_id}_#{server_attributes[:server_id]}"

#     # Make sure the value is what we want
#     server_attributes[:server_visibility] =
#       if server_attributes[:server_visibility] == "0"
#         :private
#       else
#         :public
#       end

#     # Disallow setting the ui_version to v2
#     server_attributes.delete(:ui_version) unless current_community.allow_v2_servers?

#     # Convert reward_items to a hash
#     reward_attributes[:reward_items] = JSON.parse(reward_attributes[:reward_items])
#     reward_attributes[:player_poptabs] ||= 0
#     reward_attributes[:locker_poptabs] ||= 0
#     reward_attributes[:respect] ||= 0

#     setting_attributes[:additional_logs] = JSON.parse(
#       setting_attributes[:additional_logs] || "[]"
#     )

#     # Reset extdb_path and logging_path to nil if they are ""
#     ServerSetting::CONFIG_DEFAULTS.each do |key, default_value|
#       next unless setting_attributes.key?(key)

#       value = setting_attributes[key]

#       # Set value to nil unless the user has selected something and it is different than default
#       unless value.present? && value != default_value
#         setting_attributes[key] = nil
#       end
#     end

#     # Set the server name to an empty string as that nil is not allowed
#     server_attributes[:server_name] ||= ""

#     # Return the separated attributes
#     [server_attributes, mod_attributes, reward_attributes, setting_attributes]
