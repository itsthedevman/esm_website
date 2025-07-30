# frozen_string_literal: true

class ServersController < AuthenticatedController
  before_action :check_for_community_access!

  def show
    redirect_to edit_community_server_path(current_community, params[:server_id])
  end

  def new
    render locals: {existing_server_ids:}
  end

  def edit
    server = find_server
    not_found! if server.nil?

    existing_server_mods = server.server_mods
      .select(:mod_name, :mod_link, :mod_version, :mod_required)
      .map do |mod|
        mod.attributes
          .except("id")
          .transform_keys { |k| k.to_s.split("_").second } # Remove "mod_"
      end

    render locals: {
      server:,
      existing_server_mods:,
      existing_server_ids: existing_server_ids - [server.local_id]
    }
  end

  # V1
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
      template: "servers/config",
      locals: {settings: server.server_setting.attributes},
      layout: false
    )

    send_data(config, filename: "config.yml")
  end

  def create
    server_params = permit_create_params

    server = current_community.servers.create!(server_params)

    # Add the default @Exile mod
    server.server_mods.create!(
      mod_name: "@ExileMod",
      mod_version: "1.0.4",
      mod_link: "https://steamcommunity.com/workshop/filedetails/?id=1487484880",
      mod_required: true
    )

    flash[:success] = "Server #{server.server_id} has been created"
    redirect_to edit_community_server_path(current_community, server)
  end

  def update
    server = find_server
    not_found! if server.nil?

    permit_update_params
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

  def existing_server_ids
    current_community.servers
      .select(:server_id)
      .map(&:local_id)
      .sort_by
      .insensitive
      .sort
  end

  def permit_create_params
    permitted_params = params.require(:server).permit(
      :server_id, :server_ip, :server_port,
      :server_visibility, :ui_version
    )

    sanitize_info_params(permitted_params)
  end

  def permit_update_params
    permitted_params = params.require(:server).permit(
      :server_id, :server_ip, :server_port,
      :server_visibility, :ui_version,
      server_rewards: [
        :player_poptabs,
        :locker_poptabs,
        :respect,
        items: [:classname, :quantity]
      ],
      server_mods: [:name, :version, :link, :required],
      server_settings: {}
    )

    info_params = permitted_params.except(:server_mods, :server_settings, :server_rewards)

    [
      sanitize_info_params(info_params),
      sanitize_mod_params(permitted_params[:server_mods]),
      sanitize_reward_params(permitted_params[:server_rewards]),
      sanitize_setting_params(permitted_params[:server_settings])
    ]
  end

  def sanitize_info_params(permitted_params)
    permitted_params[:server_id] =
      "#{current_community.community_id}_#{permitted_params[:server_id]}"

    permitted_params[:server_visibility] =
      if permitted_params[:server_visibility] == "0"
        :private
      else
        :public
      end

    permitted_params[:server_name] ||= ""

    version = permitted_params.delete(:ui_version)
    permitted_params[:ui_version] = "#{version}.0.0" if [1, 2].include?(version)

    permitted_params
  end

  def sanitize_mod_params(permitted_params)
    return [] if permitted_params.blank?

    permitted_params.map! { |mod| mod.transform_keys! { |k| "mod_#{k}" } } # Add back "mod_"
  end

  def sanitize_reward_params(permitted_params)
    return {} if permitted_params.blank?

    # Need to group items by their classnames and sum the values
    permitted_params[:reward_items] ||= {}
    permitted_params[:player_poptabs] ||= 0
    permitted_params[:locker_poptabs] ||= 0
    permitted_params[:respect] ||= 0

    permitted_params
  end

  def sanitize_setting_params(permitted_params)
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
  end
end
