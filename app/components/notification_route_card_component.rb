# frozen_string_literal: true

class NotificationRouteCardComponent < ApplicationComponent
  GROUPS = {
    territory_management: %w[
      flag-restored
      protection-money-due
      protection-money-paid
    ],
    base_combat: %w[
      base-raid
      flag-stolen
      flag-steal-started
      grind-started
      hack-started
      charge-plant-started
    ],
    economy: %w[
      marxet-item-sold
    ],
    custom: %w[
      custom
    ]
  }.freeze

  attr_reader :community, :server, :channel, :routes

  def on_load(community:, server:, channel:, routes:)
    @community = community
    @server = server
    @channel = channel
    @routes = routes
  end

  def territory_management_routes
    types = GROUPS[:territory_management]
    routes.select { |route| types.include?(route.notification_type) }
  end

  def base_combat_routes
    types = GROUPS[:base_combat]
    routes.select { |route| types.include?(route.notification_type) }
  end

  def economy_routes
    types = GROUPS[:economy]
    routes.select { |route| types.include?(route.notification_type) }
  end

  def custom_routes
    types = GROUPS[:custom]
    routes.select { |route| types.include?(route.notification_type) }
  end
end
