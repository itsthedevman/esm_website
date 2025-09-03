# frozen_string_literal: true

class NotificationRouteCardComponent < ApplicationComponent
  include NotificationGrouping

  attr_reader :community, :server, :channel, :all_routes

  def on_load(community:, server:, channel:, routes:)
    @community = community
    @server = server
    @channel = channel
    @all_routes = routes
  end

  def render_route_group(group_name, routes)
    content_tag(
      :div,
      class: "mb-3",
      id: group_container_id(channel, community, server, group_name)
    ) do
      safe_join([
        render_group_header(group_name),
        render_route_rows(routes)
      ])
    end
  end

  private

  def group_container_id(channel, community, server, group_name)
    "#{channel.id}-#{community.public_id}-#{server&.server_id}-#{group_name}"
  end

  def render_group_header(group_name)
    content_tag(:h6, class: "small mb-2 d-flex align-items-center") do
      content_tag(:span, group_name.humanize.upcase, class: "fw-semibold")
    end
  end

  def render_route_rows(routes)
    safe_join(routes.map { |route| render_route_row(route) })
  end

  def render_route_row(route)
    content_tag(
      :div,
      class: "d-flex align-items-center justify-content-between mb-1 route-row",
      id: route.dom_id
    ) do
      safe_join([
        render_route_controls(route),
        render_route_delete_button(route)
      ])
    end
  end

  def render_route_controls(route)
    content_tag(:div, class: "d-flex align-items-center gap-2 flex-grow-1") do
      render_route_checkbox(route)
    end
  end

  def render_route_checkbox(route)
    content_tag(:div, class: "form-check form-switch mb-0") do
      id = "route-#{route.public_id}"

      safe_join([
        check_box_tag(
          "route[#{route.public_id}]", "1",
          route.enabled?,
          id:, class: "form-check-input"
        ),
        content_tag(:label, route.notification_type.titleize, class: "small", for: id)
      ])
    end
  end

  def render_route_delete_button(route)
    button_to(
      users_notification_routing_path(route),
      method: :delete,
      class: "btn btn-link btn-sm p-0 text-danger route-delete d-none",
      title: "Delete #{route.notification_type.titleize} route"
    ) do
      content_tag(:i, "", class: "bi bi-trash small")
    end
  end
end
