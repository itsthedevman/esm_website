# frozen_string_literal: true

class CommunitiesController < AuthenticatedController
  def index
    @server_communities = current_user.server_communities
    @player_communities = current_user.player_communities

    render locals: {}
  end

  def show
    @community = ESM::Community.all.first
    render locals: {}
  end
end
