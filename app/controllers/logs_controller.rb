# frozen_string_literal: true

class LogsController < ApplicationController
  def show
    current_community = ESM::Community.find_by(public_id: params[:community_community_id])
    log = ESM::Log.includes(:log_entries, :server, :user).last

    render locals: {
      current_community:,
      log:
    }
  end
end
