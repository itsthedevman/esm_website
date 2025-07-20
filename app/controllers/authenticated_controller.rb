# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  protected

  def current_context
    current_community || current_user
  end

  helper_method :current_context

  def current_community
    return @current_community if @current_community

    public_id = params[:community_id] || params[:id]
    return if public_id.blank?

    @current_community ||= ESM::Community.all.includes(:servers).find_by(public_id:)
  end

  helper_method :current_community

  ##################################################################################################

  def check_for_community_access!
    return if current_community&.modifiable_by?(current_user)

    respond_to do |format|
      format.html { redirect_to communities_path, alert: "Page not found" }
      format.json { render json: {}, status: :unauthorized }
    end
  end

  def redirect_if_player_mode!
    return redirect_to communities_path if current_community.nil?
    return unless current_community.player_mode_enabled?

    redirect_to edit_community_path(current_community.public_id),
      alert: "Player mode is enabled on this community. You cannot access this page with it enabled."
  end

  def redirect_if_server_mode!
    return redirect_to communities_path if current_community.nil?
    return if current_community.player_mode_enabled?

    redirect_to edit_community_path(current_community.public_id),
      alert: "Player mode is not enabled on this community. You cannot access this page with it disabled."
  end
end
