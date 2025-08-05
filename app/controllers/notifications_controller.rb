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
      ["Base Raid", "xm8_raid"], # xm8; base-raid, charge-plant-started, grind-started, hack-started
      ["Flag Events", "xm8_flag"], # xm8; flag-stolen, flag-restored, flag-steal-started
      ["Money Events", "xm8_money"], # xm8; protection-money-due, protection-money-paid, marxet-item-sold
      ["Gambling Wins", "gambling_won"],
      ["Gambling Losses", "gambling_loss"],
      ["Player Currency", "player_currency"], # player; money, locker, respect
      ["Player Actions", "player_actions"] # player; heal, kill
    ]

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
    case params[:filter]
    when "xm8_all"
      notifications.with_category("xm8")
    when "gambling_all"
      notifications.with_category("gambling")
    when "xm8_raid"
      notifications.with_category("xm8").with_any_type(
        "base-raid", "charge-plant-started", "grind-started", "hack-started"
      )
    when "xm8_flag"
      notifications.with_category("xm8").with_any_type(
        "flag-stolen", "flag-restored", "flag-steal-started"
      )
    when "xm8_money" # xm8;
      notifications.with_category("xm8").with_any_type(
        "protection-money-due", "protection-money-paid", "marxet-item-sold"
      )
    when "gambling_won"
      notifications.with_category("gambling").with_type("won")
    when "gambling_loss"
      notifications.with_category("gambling").with_type("loss")
    when "player_currency"
      notifications.with_category("player").with_any_type(
        "money", "locker", "respect"
      )
    when "player_actions"
      notifications.with_category("player").with_any_type("heal", "kill")
    else
      notifications
    end
  end
end
