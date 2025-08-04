# frozen_string_literal: true

class NotificationsController < AuthenticatedController
  before_action :check_for_community_access!
  before_action :redirect_if_player_mode!

  def index
    filter_category, filter_type = (params[:filter] || "all").split("_")

    notifications = current_community.notifications.order(:community_id, :notification_type)

    notifications =
      if filter_category == "all"
        notifications
      elsif filter_type == "all"
        notifications.with_category(filter_category)
      else
        notifications.with_category(filter_category).with_type(filter_type)
      end

    notifications.load # preload, avoids extra queries

    grouped_notification_types = [
      ["XM8 Territory Events", [
        ["Base Raid", "base-raid"],
        ["Flag Stolen", "flag-stolen"],
        ["Flag Restored", "flag-restored"],
        ["Protection Money Due", "protection-money-due"],
        ["Protection Money Paid", "protection-money-paid"],
        ["Charge Plant Started", "charge-plant-started"],
        ["Grind Started", "grind-started"],
        ["Hack Started", "hack-started"],
        ["Flag Steal Started", "flag-steal-started"],
        ["MarXet Item Sold", "marxet-item-sold"]
      ]],
      ["Gambling Events", [
        ["Won", "won"],
        ["Loss", "loss"]
      ]],
      ["Player Management", [
        ["Money", "money"],
        ["Locker", "locker"],
        ["Respect", "respect"],
        ["Heal", "heal"],
        ["Kill", "kill"]
      ]]
    ]

    colors = ESM::Color::Toast.to_h
      .transform_keys { |k| k.to_s.titleize }
      .sort_by(&:first) # Name

    render locals: {
      colors:,
      grouped_notification_types:,
      notifications: notifications.sort_by(&:notification_category)
    }
  end

  def create
    # notification = Notification.new(notification_params.merge(community_id: current_community.id))

    # if notification.save
    #   render json: {notifications: current_community.notifications}
    # else
    #   render json: {message: "I'm sorry, we were unable to create the notification<br>Please try again later"}
    # end
  end

  def update
    # notification = Notification.where(id: params[:id], community_id: current_community.id).first

    # # Make sure it wasn't delete
    # if notification.nil?
    #   return render json: {message: "I'm sorry, we were unable to find the requested notification.", notifications: current_community.notifications}, status: :unprocessable_entity
    # end

    # if notification.update(notification_params.merge(community_id: current_community.id))
    #   render json: {notifications: current_community.notifications}
    # else
    #   render json: {message: "I'm sorry, we were unable to update that notification<br>Please try again later"}, status: :unprocessable_entity
    # end
  end

  def destroy
    # notification = Notification.where(id: params[:id], community_id: current_community.id).first

    # # Make sure it wasn't delete
    # if notification.nil?
    #   return render json: {message: "We were unable to find the requested notification.", notifications: current_community.notifications}, status: :unprocessable_entity
    # end

    # if notification.destroy
    #   render json: {notifications: current_community.notifications}
    # else
    #   render json: {message: "I'm sorry, we were unable to delete that notification<br>Please try again later"}, status: :unprocessable_entity
    # end
  end

  private

  def notification_params
    # params.require("notification").permit(:notification_category, :notification_type, :notification_title, :notification_description, :notification_color)
  end
end
