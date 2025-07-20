# frozen_string_literal: true

class CommunitiesController < AuthenticatedController
  def index
    @server_communities = ESM::Community.all.player_mode_disabled
    @player_communities = [] # ESM::Community.all.player_mode_enabled

    render locals: {}
  end

  def show
    @community = ESM::Community.all.first
    render locals: {}
  end
end
