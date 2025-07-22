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

  private

  def role_to_hash(role, selected: false)
    {
      label: role.name,
      value: role.id,
      disabled: role.disabled,
      selected:
    }
  end
end
