# frozen_string_literal: true

class ServersController < AuthenticatedController
  before_action :check_for_community_access!

  def show
    redirect_to edit_community_server_path(current_community, params[:server_id])
  end

  def new
    existing_server_ids = current_community.servers
      .pluck(:server_id)
      .map { |id| id.split("_").second }
      .sort_by
      .insensitive
      .sort

    render locals: {existing_server_ids:}
  end

  def edit
    server = current_community.servers.find_by(public_id: params[:server_id])

    render locals: {server:}
  end

  def create
    server_params = permit_new_server_params

    server = current_community.servers.create!(server_params)

    flash[:success] = "Server #{server.server_id} has been created"
    redirect_to edit_community_server_path(current_community, server)
  end

  private

  def permit_new_server_params
    @permit_new_server_params ||= begin
      permitted_params = params.require(:server).permit(
        :server_id, :server_ip, :server_port,
        :server_visibility, :ui_version
      )

      permitted_params[:server_id] =
        "#{current_community.community_id}_#{permitted_params[:server_id]}"

      permitted_params[:server_visibility] =
        if permitted_params[:server_visibility] == "0"
          :private
        else
          :public
        end

      version = permitted_params.delete(:ui_version)
      permitted_params[:ui_version] = "#{version}.0.0" if [1, 2].include?(version)

      permitted_params
    end
  end
end
