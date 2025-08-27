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
    routes = current_user.user_notification_routes.by_community_server_and_channel_for_user

    render locals: {
      routes:
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

  def destroy
    route = current_context.user_notification_routes.where(uuid: params[:id]).first
    return check_failed!(message: "Failed to find the requested route") if route.blank?

    route.destroy!

    message = "#{route.notification_type.titleize} notifications from #{route.source_server&.server_name || "any server"} will no longer route to this channel"
    message =
      if current_context == current_community
        "#{route.user.user_name}'s #{message}"
      else
        "Your #{message}"
      end

    render json: {message: message}, status: :ok
  end

  def destroy_many
    routes = current_context.user_notification_routes.where(uuid: params[:ids])
    return check_failed!(message: "Failed to find the requested routes") if routes.blank?

    routes.each(&:destroy)

    route = routes.first
    message = "notifications from #{route.source_server&.server_name || "any server"} will no longer route to this channel"
    message =
      if current_context == current_community
        "#{route.user.user_name}'s #{message}"
      else
        "Your #{message}"
      end

    render json: {message: message}, status: :ok
  end

  def accept_requests
    routes = current_context.user_notification_routes.where(uuid: params[:ids])
    return check_failed!(message: "Failed to find the requested routes") if routes.blank? || routes.size != params[:ids].size

    if current_community
      routes.update_all(community_accepted: true, updated_at: Time.current)
    else
      routes.update_all(user_accepted: true, updated_at: Time.current)
    end

    render json: {message: "#{"Request".pluralize(routes.size)} accepted"}

    notify_channel(routes)
  end

  def decline_requests
    routes = current_context.user_notification_routes.where(uuid: params[:ids])
    return check_failed!(message: "Failed to find the requested routes") if routes.blank? || routes.size != params[:ids].size

    routes.delete_all
    render json: {message: "#{"Request".pluralize(routes.size)} declined"}
  end

  def accept_all_requests
    pending_requests =
      if current_context == current_community
        current_community.user_notification_routes.pending_community_acceptance
      else
        current_user.user_notification_routes.pending_user_acceptance
      end

    grouped_routes = pending_requests.by_channel_server_and_user.values
    grouped_routes.each do |routes|
      updated_fields = {updated_at: Time.current}

      if current_context == current_community
        updated_fields[:community_accepted] = true
      else
        updated_fields[:user_accepted] = true
      end

      UserNotificationRoute.where(id: routes.map(&:id)).update_all(**updated_fields)

      notify_channel(routes)
    end

    render json: {message: "All requests accepted"}
  end

  def decline_all_requests
    pending_requests =
      if current_context == current_community
        current_community.user_notification_routes.pending_community_acceptance
      else
        current_user.user_notification_routes.pending_user_acceptance
      end

    pending_requests.delete_all
    render json: {message: "All requests declined"}
  end

  private

  def route_params
    # server_ids and types can be an array or a string
    @route_params ||= params.permit(:server_ids, :types, :community_id, :channel_id, user_ids: [], types: [], server_ids: [])
  end

  def notify_channel(routes)
    # Everything is grouped so all the requests are for one user, from one server, routing to one channel
    template_route = routes.first
    user = template_route.user

    types_sentence =
      if UserNotificationRoute::TYPES.size == routes.size
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

    ESM.send_message(
      channel_id: template_route.channel_id,
      message: <<~STRING
        :incoming_envelope: #{user.mention}, this channel will now receive #{types_sentence} XM8 notifications sent to you from #{server}
      STRING
    )
  end
end
