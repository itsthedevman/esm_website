# frozen_string_literal: true

class CommunitiesController < AuthenticatedController
  def index
    server_communities = current_user.server_communities.load
    player_communities = current_user.player_communities.load

    render locals: {
      server_communities:,
      player_communities:
    }
  end

  def show
    check_for_community_access!

    render locals: {}
  end
end
