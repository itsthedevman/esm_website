# frozen_string_literal: true

class UserNotificationRoutesController < AuthenticatedController
  before_action :redirect_if_server_mode!, if: -> { current_context == current_community }

  def server_index
    # render action_name, locals: {
    #   servers: Community.servers_by_community,
    #   channels: load_admin_channels,
    #   pending_requests: load_pending_requests,
    #   types: load_types,
    #   users: load_users,
    #   type_presets: load_type_presets,
    #   view_path: "user_notification_routes/server"
    # }
  end

  def player_index
    routes = current_user.user_notification_routes
      .accepted
      .by_community_server_and_channel_for_user

    pending_routes = current_user.user_notification_routes
      .pending_user_acceptance
      .by_community_server_and_channel_for_user

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

    render locals: {
      routes:,
      pending_routes:,
      community_select_data: helpers.generate_community_select_data(
        all_communities,
        value_method: ->(community) { "#{community.community_id}:#{community.community_name}" }
      ),
      server_select_data: helpers.generate_server_select_data(
        servers_by_community,
        value_method: ->(server) { "#{server.server_id}:#{server.server_name}" },
        select_all: true
      ),
      notification_type_select_data: generate_type_select_data
    }
  end

  def create
    # Validate and load the users
    users =
      if route_params[:user_ids].present?
        users = User.where(discord_id: route_params[:user_ids]).select(:id)
        return check_failed!(message: "Failed to find the requested users") if users.blank? || users.size != route_params[:user_ids].size

        users
      else
        [current_user]
      end

    # Validate the community. If we're modifying this from the server dashboard, current_community will be defined.
    community = current_community || Community.find_by_community_id(route_params[:community_id])
    return check_failed!(message: "Failed to find the requested community") if community.nil?

    # Validate the channel
    filter =
      if current_context == current_community
        {community_id: current_community.id}
      else
        {user_id: current_user.id}
      end

    channel = ESM.channel(route_params[:channel_id], **filter)
    return check_failed!(message: "You do not have access to that channel") if channel.nil?

    # Presets for types :)
    types =
      case route_params[:types]
      when "any"
        UserNotificationRoute::TYPES
      when "raids"
        UserNotificationRoute::TYPE_PRESETS[:raids]
      when "payments"
        UserNotificationRoute::TYPE_PRESETS[:payments]
      else
        UserNotificationRoute::TYPES.select { |type| type.in?(route_params[:types]) }
      end

    # Validate the servers
    servers =
      if route_params[:server_ids].is_a?(String) && route_params[:server_ids].casecmp?("any")
        [nil]
      else
        servers = Server.where(server_id: route_params[:server_ids]).select(:id)
        return check_failed!(message: "Failed to find the requested servers") if servers.blank? || servers.size != route_params[:server_ids].size

        servers
      end

    # This builds all of the queries as Array<Hash>
    queries = users.map do |user|
      # This auto accepts any requests for the current user
      auto_accept =
        if current_context == current_community
          current_user == user
        else
          current_user == user && community.modifiable_by?(current_user)
        end

      types.map do |type|
        servers.map do |server|
          {
            uuid: SecureRandom.uuid,
            user_id: user.id,
            source_server_id: server&.id,
            destination_community_id: community.id,
            channel_id: channel[:id],
            notification_type: type,
            community_accepted: auto_accept || current_context == current_community,
            user_accepted: auto_accept || current_context == current_user
          }
        end
      end
    end.flatten

    # Remove any duplicates
    queries.reject! { |query| UserNotificationRoute.where(query.except(:community_accepted, :uuid)).exists? }

    # I love bulk inserts
    UserNotificationRoute.import(queries)

    # Check if any were auto-accepted and notify the channel
    accepted_uuids = queries.select { |query| query[:community_accepted] && query[:user_accepted] }.map { |query| query[:uuid] }
    routes = UserNotificationRoute.where(uuid: accepted_uuids)
    notify_channel(routes) if routes.present?

    render json: {
      routes: current_context.user_notification_routes.where(channel_id: channel[:id]).clientize,
      message: "#{"Request".pluralize(queries.size)} sent. ESM will send a message to <span class='esm-text-color-toast-blue'>##{channel[:name]}</span> when the request has been accepted"
    }, status: :created
  end

  def update
    route = current_context.user_notification_routes.where(uuid: params[:id]).first
    return check_failed!(message: "Failed to find the requested route") if route.blank?

    route.update!(enabled: params[:enabled])

    message = "#{route.notification_type.titleize} notifications are now #{route.enabled? ? "enabled" : "disabled"} for this channel"
    message =
      if current_context == current_community
        "#{route.user.user_name}'s #{message}"
      else
        "Your #{message}"
      end

    render json: {message: message}, status: :ok
  end

  def accept
    ids = params[:ids].to_a
    not_found! if ids.blank?

    routes = current_context.user_notification_routes.where(public_id: ids)
    not_found! if routes.blank? || routes.size != ids.size

    if current_community
      routes.update_all(community_accepted: true, updated_at: Time.current)
    else
      routes.update_all(user_accepted: true, updated_at: Time.current)
    end

    notify_channel(routes)

    flash[:success] = "Request accepted"

    if current_community
      redirect_to community_notification_routing_index_path
    else
      redirect_to users_notification_routing_index_path
    end
  end

  def decline
    ids = params[:ids].to_a
    not_found! if ids.blank?

    routes = current_context.user_notification_routes.where(public_id: ids)
    not_found! if routes.blank? || routes.size != ids.size

    routes.delete_all

    flash[:success] = "Request declined"

    if current_community
      redirect_to community_notification_routing_index_path
    else
      redirect_to users_notification_routing_index_path
    end
  end

  def destroy
    route = current_context.user_notification_routes
      .includes(:destination_community, :source_server)
      .find_by(public_id: params[:id])

    not_found! if route.nil?

    route.destroy!

    # No routes left? Refresh the page
    if current_context.user_notification_routes.size == 0
      flash[:success] = "Route has been removed"
      render turbo_stream: turbo_stream.refresh(request_id: nil)
      return
    end

    actions = [
      turbo_stream.remove(route.dom_id),
      create_success_toast("Route has been removed")
    ]

    # If the last route in a group has been removed, remove the group too
    if (dom_id = remove_route_group(route))
      actions << turbo_stream.remove(dom_id)

      # Since we removed the group, check if we need to remove the card too
      if (dom_id = remove_route_card(route))
        actions << turbo_stream.remove(dom_id)
      end
    end

    render turbo_stream: actions
  end

  def destroy_many
    routes = current_context.user_notification_routes
      .includes(:destination_community, :source_server)
      .where(public_id: params[:ids])

    not_found! if routes.blank?

    routes.each(&:destroy!)

    # No routes left? Refresh the page
    if current_context.user_notification_routes.size == 0
      flash[:success] = "Routes have been removed"
      render turbo_stream: turbo_stream.refresh(request_id: nil)
      return
    end

    route = routes.first
    community = route.destination_community
    server = route.source_server

    render turbo_stream: [
      turbo_stream.remove("#{route.channel_id}-#{community.public_id}-#{server&.public_id}"),
      create_success_toast("Routes have been removed")
    ]
  end

  private

  def route_params
    # server_ids and types can be an array or a string
    @route_params ||= params.permit(:server_ids, :types, :community_id, :channel_id, user_ids: [], types: [], server_ids: [])
  end

  def notify_channel(routes)
    # Everything is grouped so all the requests are for one user
    # from one server routing to one channel
    template_route = routes.first
    user = template_route.user

    types_sentence =
      if ESM::UserNotificationRoute::TYPES.size == routes.size
        "all"
      else
        routes.map { |route| "`#{route.notification_type.titleize}`" }.to_sentence
      end

    server =
      if template_route.source_server
        "`#{template_route.source_server.server_id}`"
      else
        "any server"
      end

    ESM.bot.send_message(
      channel_id: template_route.channel_id,
      message: <<~STRING
        :incoming_envelope: #{user.mention}, this channel will now receive #{types_sentence} XM8 notifications sent to you from #{server}
      STRING
    )
  end

  def remove_route_group(route)
    group_name, group_types = ESM::UserNotificationRoute::GROUPS
      .find { |_, v| v.include?(route.notification_type) }

    group_routes_exist = current_context.user_notification_routes.where(
      channel_id: route.channel_id,
      destination_community_id: route.destination_community_id,
      source_server_id: route.source_server_id,
      notification_type: group_types
    ).exists?

    return if group_routes_exist

    server = route.source_server
    community = route.destination_community

    "#{route.channel_id}-#{community.public_id}-#{server&.server_id}-#{group_name}"
  end

  def remove_route_card(route)
    routes_exist = current_context.user_notification_routes.where(
      channel_id: route.channel_id,
      destination_community_id: route.destination_community_id,
      source_server_id: route.source_server_id
    ).exists?

    return if routes_exist

    server = route.source_server
    community = route.destination_community

    "#{route.channel_id}-#{community.public_id}-#{server&.public_id}"
  end

  def generate_type_select_data
    helpers.group_data_from_collection_for_slim_select(
      ESM::UserNotificationRoute::GROUPS,
      ->(key) { key.to_s.titleize.upcase },
      :itself,
      ->(i) { i.titleize },
      placeholder: true
    )
  end
end
