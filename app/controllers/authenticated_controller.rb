# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  protected

  def current_context
    current_community || current_user
  end

  def current_community
    @community
  end

  def check_for_access
    return if (params[:user_id] || params[:id]) == current_user.discord_id

    @community = ESM::Community.find_by(public_id: params[:community_id] || params[:id])
    return if current_community&.modifiable_by?(current_user)

    respond_to do |format|
      format.html { redirect_to root_path, alert: "You are not allowed to view that page" }
      format.json { render json: {}, status: :unauthorized }
    end
  end

  def redirect_if_player_mode
    return redirect_to communities_path if current_community.nil?
    return unless current_community.player_mode_enabled?

    redirect_to edit_community_path(current_community.public_id),
      alert: "Player mode is enabled on this community. You cannot access this page with it enabled."
  end

  def redirect_if_not_player_mode
    return redirect_to communities_path if current_community.nil?
    return if current_community.player_mode_enabled?

    redirect_to edit_community_path(current_community.public_id),
      alert: "Player mode is not enabled on this community. You cannot access this page with it disabled."
  end

  def check_failed!(opts = {})
    respond_to do |format|
      format.html do
        flash[:error] = opts[:message]
        redirect_to opts[:redirect_to] || root_path
      end

      format.json { render json: {message: opts[:message]}, status: opts[:status] || :bad_request }
    end

    Rails.logger.error { opts[:message] }

    true
  end
end
