# frozen_string_literal: true

class UsersController < AuthenticatedController
  skip_before_action :authenticate_user!
  before_action :authenticate_user!, except: :register

  def edit
    all_communities = ESM::Community.select(:id, :community_id, :community_name)
      .order("UPPER(community_id)")
      .load

    servers_by_community = ESM::Server.select(:id, :community_id, :server_id, :server_name)
      .includes(:community)
      .order("UPPER(server_id)")
      .load
      .group_by(&:community)
      .sort_by.method(:first).case_insensitive
      .to_a
      .to_h

    id_defaults = current_user.id_defaults
    id_aliases = current_user.id_aliases
      .includes(:community, :server)
      .load
      .sort_by(:value).case_insensitive
      .map(&:public_attributes)
      .index_by { |a| a["id"] }

    render locals: {
      # Defaults
      id_defaults:,
      default_community_select_data:
        generate_community_select_data(all_communities, id_defaults.community_id),
      default_server_select_data:
        generate_server_select_data(servers_by_community, id_defaults.server_id),

      # Aliases
      id_aliases:,
      alias_community_select_data: generate_community_select_data(
        all_communities,
        value_method: ->(community) { "#{community.community_id}:#{community.community_name}" }
      ),
      alias_server_select_data: generate_server_select_data(
        servers_by_community,
        value_method: ->(server) { "#{server.server_id}:#{server.server_name}" }
      )
    }
  end

  def update
    permitted_params = permit_update_params!

    if (id_defaults = permitted_params[:defaults])
      update_id_defaults!(id_defaults)
    end

    binding.pry

    render turbo_stream: create_success_toast("Your settings have been updated")
  end

  # def transfer_account
  #   if session[:transfer_steam_account].blank?
  #     flash[:alert] = "You are not authorized to view that page"
  #     return redirect_to root_path
  #   end

  #   steam_uid = session[:transfer_steam_account]

  #   # Remove it immediately
  #   session.delete(:transfer_steam_account)

  #   # Unset all users with this steam_uid
  #   User.where(steam_uid:).update_all(steam_uid: "")

  #   # Transfer this uid to the new user and refresh their data
  #   current_user.update!(steam_uid:)

  #   flash[:success] = {
  #     title: "Welcome #{current_user.steam_data.username}!",
  #     message: "You are now registered with ESM<br/>We've sent you a message via Discord to help you get started",
  #     hide_after: 8000
  #   }

  #   ESM.send_message(
  #     channel_id: current_user.discord_id,
  #     message: {
  #       author: {
  #         name: current_user.steam_data.username,
  #         icon_url: current_user.steam_data.avatar
  #       },
  #       title: "Successfully Registered!",
  #       description: "You have been registered with Exile Server Manager. This allows you to use ESM on any server running ESM that you join. You don't even have to be in their Discord!\n**Below is some important information to get you started.**",
  #       color: ESM::COLORS::GREEN,
  #       fields: [{
  #         name: "Getting Started",
  #         value: "First time using ESM or need a refresher? Come read the [Getting Started](https://www.esmbot.com/wiki) article to help get you acquainted"
  #       }, {
  #         name: "Commands",
  #         value: "Need to feel powerful? Check out my [commands](https://www.esmbot.com/wiki/commands) and come back to show off your new found knowledge!"
  #       }]
  #     }
  #   )

  #   redirect_to edit_user_path(current_user.discord_id)
  # end

  # def cancel_transfer
  #   session.delete(:transfer_steam_account)
  #   render json: {}
  # end

  def destroy
    current_user.destroy!
    sign_out(current_user)

    flash[:success] = "Your account has been deleted"
    redirect_to root_path
  end

  def register
    raise "Register"
    # session[:registering] = true
    # render "layouts/oauth_login", locals: {url: user_discord_omniauth_authorize_path}
  end

  def deregister
    current_user.deregister!

    flash[:success] = "You've been deregistered.<br/>You can reregister via the Sign into Steam button"
    redirect_to edit_users_path
  end

  private

  def generate_community_select_data(all_communities, selected_id = nil, value_method: nil)
    value_method ||= :community_id

    text_method = ->(community) { "[#{community.community_id}] #{community.community_name}" }
    selected = selected_id ? ->(item, _value) { item.id == selected_id } : false

    helpers.data_from_collection_for_slim_select(
      all_communities, value_method, text_method,
      selected:, placeholder: true
    )
  end

  def generate_server_select_data(servers_by_community, selected_id = nil, value_method: nil)
    group_label_method = ->(community) { "[#{community.community_id}] #{community.community_name}" }

    value_method ||= :server_id

    text_method = lambda do |server|
      "[#{server.server_id}] #{server.server_name || "Name not provided"}"
    end

    selected = selected_id ? ->(item, _value) { item.id == selected_id } : false

    helpers.group_data_from_collection_for_slim_select(
      servers_by_community, group_label_method, value_method, text_method,
      selected:, placeholder: true
    )
  end

  def permit_update_params!
    params.require(:user).permit(
      defaults: [:community_id, :server_id]
    )
  end

  def update_id_defaults!(id_defaults)
    if (community_id = id_defaults.delete(:community_id))
      id_defaults[:community_id] = ESM::Community.with_community_id(community_id).pick(:id)
    end

    if (server_id = id_defaults.delete(:server_id))
      id_defaults[:server_id] = ESM::Server.with_server_id(server_id).pick(:id)
    end

    ESM::UserDefault.where(user_id: current_user.id).update!(id_defaults)
  end
end
