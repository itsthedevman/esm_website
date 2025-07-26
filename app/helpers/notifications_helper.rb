# frozen_string_literal: true

module NotificationsHelper
  # Check if we're currently editing or creating a notification
  def editing_notification?
    current_notification.present?
  end

  # Get the current notification being edited/created
  def current_notification
    @notification
  end

  # Map notification categories to Bootstrap badge colors
  def notification_category_color(category)
    case category.to_s.downcase
    when "xm8"
      "success"
    when "gambling"
      "warning"
    when "player"
      "info"
    else
      "secondary"
    end
  end

  # Generate sample server data for previews
  def sample_server_id
    @sample_server_id ||= current_community.servers.first&.server_id || "#{current_community.community_id}_example"
  end

  def sample_server_name
    @sample_server_name ||= current_community.servers.first&.server_name || "Example Server"
  end

  # Preview notification title with variable substitution
  def preview_title(notification)
    return "Preview title will appear here" if notification.notification_title.blank?

    substitute_notification_variables(notification, notification.notification_title)
  end

  # Preview notification description with variable substitution
  def preview_description(notification)
    return "Preview message will appear here" if notification.notification_description.blank?

    substitute_notification_variables(notification, notification.notification_description)
  end

  private

  # Handle variable substitution for notification previews
  def substitute_notification_variables(notification, text)
    # Global variables available for all notifications
    text = text.gsub(/\{\{\s*serverID\s*\}\}/i, sample_server_id)
      .gsub(/\{\{\s*serverName\s*\}\}/i, sample_server_name)
      .gsub(/\{\{\s*communityID\s*\}\}/i, current_community.community_id)
      .gsub(/\{\{\s*userName\s*\}\}/i, sample_user_name)
      .gsub(/\{\{\s*userTag\s*\}\}/i, sample_user_tag)

    # Category-specific variables
    case notification.notification_category&.downcase
    when "xm8"
      text = substitute_xm8_variables(text)
    when "gambling"
      text = substitute_gambling_variables(text)
    when "player"
      text = substitute_player_variables(notification, text)
    end

    text
  end

  # XM8 notification variables
  def substitute_xm8_variables(text)
    text.gsub(/\{\{\s*territoryID\s*\}\}/i, sample_territory_id)
      .gsub(/\{\{\s*territoryName\s*\}\}/i, sample_territory_name)
  end

  # Gambling notification variables
  def substitute_gambling_variables(text)
    text.gsub(/\{\{\s*amountChanged\s*\}\}/i, sample_amount_changed)
      .gsub(/\{\{\s*amountGambled\s*\}\}/i, sample_amount_gambled)
      .gsub(/\{\{\s*lockerBefore\s*\}\}/i, sample_locker_before)
      .gsub(/\{\{\s*lockerAfter\s*\}\}/i, sample_locker_after)
  end

  # Player notification variables
  def substitute_player_variables(notification, text)
    text = text.gsub(/\{\{\s*targetUID\s*\}\}/i, sample_target_uid)

    # Money/locker/respect specific variables
    if %w[money locker respect].include?(notification.notification_type)
      text = text.gsub(/\{\{\s*modifiedAmount\s*\}\}/i, sample_modified_amount)
        .gsub(/\{\{\s*previousAmount\s*\}\}/i, sample_previous_amount)
        .gsub(/\{\{\s*newAmount\s*\}\}/i, sample_new_amount)
    end

    text
  end

  # Sample data generators for previews
  def sample_user_name
    "PlayerName"
  end

  def sample_user_tag
    "@PlayerName"
  end

  def sample_territory_id
    "AB123"
  end

  def sample_territory_name
    "Awesome Base"
  end

  def sample_amount_changed
    "15,000"
  end

  def sample_amount_gambled
    "5,000"
  end

  def sample_locker_before
    "100,000"
  end

  def sample_locker_after
    "115,000"
  end

  def sample_target_uid
    "76561198012345678"
  end

  def sample_modified_amount
    "10,000"
  end

  def sample_previous_amount
    "50,000"
  end

  def sample_new_amount
    "60,000"
  end
end
