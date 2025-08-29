# frozen_string_literal: true

class RouteRequestCardComponent < ApplicationComponent
  include NotificationGrouping

  attr_reader :community, :server, :channel, :all_routes

  def on_load(community:, server:, channel:, routes:)
    @community = community
    @server = server
    @channel = channel
    @all_routes = routes
  end

  def render_route_group(group_name, routes)
    content_tag :div, nil, class: "mb-3" do
      header = content_tag :div, group_name.humanize.upcase, class: "h6 small text-muted mb-2"

      routes_section = content_tag :div, nil, class: "d-flex flex-wrap gap-1" do
        safe_join(routes.map do |route|
          content_tag :span, route.notification_type.humanize, class: "badge bg-secondary"
        end)
      end

      safe_join([header, routes_section])
    end
  end
end
