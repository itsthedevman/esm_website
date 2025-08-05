# frozen_string_literal: true

class NotificationsController < AuthenticatedController
  before_action :check_for_community_access!
  before_action :redirect_if_player_mode!

  def index
    filters = [
      ["All", "all"],
      ["XM8", "xm8_all"],
      ["Gambling", "gambling_all"],
      ["Player", "player_all"],
      ["─────", "", disabled: true],
      ["Flag Events", "xm8_flag"],
      ["Gambling Losses", "gambling_loss"],
      ["Gambling Wins", "gambling_won"],
      ["Money Events", "xm8_money"],
      ["Player Actions", "player_actions"],
      ["Player Currency", "player_currency"],
      ["Raid Events", "xm8_raid"]
    ]

    grouped_notification_types = [
      ["Gambling Events", [
        ["Loss", "loss"],
        ["Won", "won"]
      ]],
      ["Player Management", [
        ["Healed", "heal"],
        ["Killed", "kill"],
        ["Locker Changed", "locker"],
        ["Money Changed", "money"],
        ["Respect Changed", "respect"]
      ]],
      ["Territory Events", [
        ["Base Raid", "base-raid"],
        ["Charge Plant Started", "charge-plant-started"],
        ["Flag Restored", "flag-restored"],
        ["Flag Steal Started", "flag-steal-started"],
        ["Flag Stolen", "flag-stolen"],
        ["Grind Started", "grind-started"],
        ["Hack Started", "hack-started"],
        ["MarXet Item Sold", "marxet-item-sold"],
        ["Protection Money Due", "protection-money-due"],
        ["Protection Money Paid", "protection-money-paid"]
      ]]
    ]

    colors = ESM::Color::Toast.to_h
      .transform_keys { |k| k.to_s.titleize }
      .sort_by(&:first) # Name
      .push(
        ["─────", "", disabled: true],
        ["Custom", "custom"],
        ["Random", "random"]
      )

    render locals: {
      colors:, filters:,
      grouped_notification_types:,
      notifications: load_notifications
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

  def load_notifications
    notifications = current_community.notifications.order(:community_id, :notification_type)

    filter_notifications(notifications)
      .load # Avoid extra queries
      .sort_by(&:notification_category)
  end

  def filter_notifications(notifications)
    category, type = (params[:filter] || "all").split("_")
    return notifications if category == "all"

    if ESM::Notification::CATEGORIES.include?(category)
      notifications = notifications.with_category(category)
    end

    case type
    when "actions"
      notifications.with_any_type("heal", "kill")
    when "currency"
      notifications.with_any_type("money", "locker", "respect")
    when "flag"
      notifications.with_any_type("flag-stolen", "flag-restored", "flag-steal-started")
    when "loss"
      notifications.with_type("loss")
    when "money"
      notifications.with_any_type(
        "protection-money-due", "protection-money-paid", "marxet-item-sold"
      )
    when "raid"
      notifications.with_any_type(
        "base-raid", "charge-plant-started", "grind-started", "hack-started"
      )
    when "won"
      notifications.with_type("won")
    else
      # xm8_all, player_all, gambling_all
      notifications
    end
  end
end
