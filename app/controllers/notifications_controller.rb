# frozen_string_literal: true

class NotificationsController < AuthenticatedController
  before_action :check_for_community_access!
  before_action :redirect_if_player_mode!

  def index
    filter_category, filter_type = (params[:filter] || "all").split("_")

    notifications = current_community.notifications

    notifications =
      if filter_category == "all"
        notifications
      elsif filter_type == "all"
        notifications.with_category(filter_category)
      else
        notifications.with_category(filter_category).with_type(filter_type)
      end

    render locals: {notifications:}
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
