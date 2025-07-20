# frozen_string_literal: true

class CommunitiesController < ApplicationController
  def index
    @server_communities = []#ESM::Community.all.player_mode_disabled
    @player_communities = []#ESM::Community.all.player_mode_enabled

    render locals: {}
  end

  def show
  end
end
