# frozen_string_literal: true

class CommunitiesController < AuthenticatedController
  before_action :check_for_community_access!, except: [:index]

  def index
    server_communities = current_user.server_communities.load
    player_communities = current_user.player_communities.load

    render locals: {
      server_communities:,
      player_communities:
    }
  end

  def show
    redirect_to edit_community_path(current_community)
  end

  def edit
    # Array<id="", name="", color="", disabled=false>
    community_roles = current_community.roles

    territory_admin_roles = community_roles.map do |role|
      selected = current_community.territory_admin_ids.include?(role.id)

      role_to_hash(role, selected:)
    end

    access_roles = community_roles.map do |role|
      selected = current_community.dashboard_access_role_ids.include?(role.id)

      role_to_hash(role, selected:)
    end

    render locals: {community_roles:, territory_admin_roles:, access_roles:}
  end

  def can_change_id
    # return render json: true if params[:id] == params[:new_community_id]

    # community = Community.find_by_community_id(params[:new_community_id])
    # render json: community.nil?
  end

  def update
    community_id = params.dig(:community, :community_id)
    community_id = community_id.downcase if community_id.present?

    community_data = community_params
    (community_data[:territory_admin_ids] ||= []).compact_blank!
    (community_data[:dashboard_access_role_ids] ||= []).compact_blank!

    # The ID has changed, update the community and servers
    if community_id.present? && community_id != current_community.community_id
      # Check to see if it exists
      if ESM::Community.by_community_id(community_id).exists?
        redirect_to edit_community_path(current_community),
          alert: "<code>#{community_id}</code> is already in use, please provide a different ID"

        return
      end

      current_community.update_community_id!(community_id)
    end

    current_community.update!(community_data)
  end

  def destroy
    # if ESM.bot.delete_community(current_community.id, current_user.id)
    #   flash[:success] = "ESM is no longer a member of #{current_community.community_name}, and any data related to #{current_community.community_id} has been deleted. If you'd like to re-create this community, please re-invite ESM your Discord"
    #   redirect_to communities_path
    # else
    #   Rails.logger.error("ERROR: #{current_community.errors}")

    #   redirect_to communities_path, alert: "Failed to delete community<br><span class='esm-text-color-red'>Please log out and log back in again</span><br>If this error persists, please join our Discord and let us know."
    # end
  end

  private

  def role_to_hash(role, selected: false)
    {
      label: role.name,
      value: role.id,
      disabled: role.disabled,
      selected:
    }
  end

  def community_params
    # Purposely not including :community_id
    params.require(:community).permit(
      :logging_channel_id,
      :log_reconnect_event, :log_xm8_event, :log_discord_log_event,
      :welcome_message_enabled, :welcome_message,
      territory_admin_ids: [], dashboard_access_role_ids: []
    )
  end
end
