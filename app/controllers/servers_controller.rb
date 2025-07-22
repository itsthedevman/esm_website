# frozen_string_literal: true

class ServersController < AuthenticatedController
  before_action :check_for_community_access!

  def show
    server = current_community.servers.find_by(public_id: params[:server_id])

    render locals: {server:}
  end
end
