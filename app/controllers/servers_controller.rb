# frozen_string_literal: true

class ServersController < AuthenticatedController
  before_action :check_for_community_access!

  def show
    redirect_to edit_community_server_path(current_community, params[:server_id])
  end

  def edit
    server = current_community.servers.find_by(public_id: params[:server_id])

    render locals: {server:}
  end
end
