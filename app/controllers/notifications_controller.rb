# frozen_string_literal: true

class NotificationsController < AuthenticatedController
  before_action :check_for_community_access!
  before_action :redirect_if_player_mode!

  def index
    render locals: {
      colors: load_colors,
      filters: load_filters,
      grouped_notification_types: load_grouped_notification_types,
      notifications: load_notifications,
      variables: load_variables
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

  def load_colors
    ESM::Color::Toast.to_h
      .transform_keys { |k| k.to_s.titleize }
      .sort_by(&:first) # Name
      .push(
        ["─────", "", disabled: true],
        ["Custom", "custom"],
        ["Random", "random"]
      )
  end

  def load_filters
    [
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
  end

  def load_grouped_notification_types
    [
      ["Gambling Events", [
        ["Loss", "gambling_loss"],
        ["Won", "gambling_won"]
      ]],
      ["Player Management", [
        ["Healed", "player_heal"],
        ["Killed", "player_kill"],
        ["Locker Changed", "player_locker"],
        ["Money Changed", "player_money"],
        ["Respect Changed", "player_respect"]
      ]],
      ["Territory Events", [
        ["Base Raid", "xm8_base-raid"],
        ["Charge Plant Started", "xm8_charge-plant-started"],
        ["Flag Restored", "xm8_flag-restored"],
        ["Flag Steal Started", "xm8_flag-steal-started"],
        ["Flag Stolen", "xm8_flag-stolen"],
        ["Grind Started", "xm8_grind-started"],
        ["Hack Started", "xm8_hack-started"],
        ["MarXet Item Sold", "xm8_marxet-item-sold"],
        ["Protection Money Due", "xm8_protection-money-due"],
        ["Protection Money Paid", "xm8_protection-money-paid"]
      ]]
    ]
  end

  def load_variables
    sample_server = current_community.servers.sample
    sample_username = current_user.discord_username || "PlayerName"

    {
      global: {
        serverID: {
          description: "Shows which server triggered this event (e.g. 'abc4_altis')",
          placeholder: sample_server&.server_id || "#{current_community.community_id}_example"
        },
        serverName: {
          description: "Friendly server name players will recognize",
          placeholder: sample_server&.server_name || "Example Server"
        },
        communityID: {
          description: "Your community's short ID for player reference",
          placeholder: current_community.community_id
        },
        userName: {
          description: "Steam username of the player involved in this event",
          placeholder: sample_username
        },
        userTag: {
          description: "Discord-style mention format (@username)",
          placeholder: "@#{sample_username}"
        }
      },

      gambling: {
        amountChanged: {
          description: "Net gain/loss from the gambling attempt",
          placeholder: Faker::Commerce.price(range: 1_000..100_000, as_string: true)
        },
        amountGambled: {
          description: "Original bet amount the player risked",
          placeholder: Faker::Commerce.price(range: 1_000..25_000, as_string: true)
        },
        lockerBefore: {
          description: "Player's bank balance before gambling",
          placeholder: Faker::Commerce.price(range: 50_000..500_000, as_string: true)
        },
        lockerAfter: {
          description: "Player's bank balance after gambling",
          placeholder: Faker::Commerce.price(range: 60_000..600_000, as_string: true)
        }
      },

      xm8: {
        territoryID: {
          description: "Territory's public ID that players use in commands",
          placeholder: Faker::Alphanumeric.alpha(number: 5).upcase
        },
        territoryName: {
          description: "Custom territory name set by the owner",
          placeholder: ["Awesome Base", "Fort Knox", "The Compound", "Safe Haven"].sample
        }
      },

      marxet: {
        item: {
          description: "Item classname that was sold on the marketplace",
          placeholder: %w[Exile_Item_PowerDrink Exile_Item_EnergyDrink Exile_Weapon_AK74].sample
        },
        amount: {
          description: "Poptabs received from the marketplace sale",
          placeholder: Faker::Commerce.price(range: 500..50_000, as_string: true)
        }
      },

      player_actions: {
        targetUID: {
          description: "Steam UID of the player who was healed/killed",
          placeholder: "76561198#{Faker::Number.number(digits: 9)}"
        }
      },

      player_currency: {
        targetUID: {
          description: "Steam UID of the player whose currency was modified",
          placeholder: "76561198#{Faker::Number.number(digits: 9)}"
        },
        modifiedAmount: {
          description: "Amount of poptabs/respect that was added or removed",
          placeholder: Faker::Commerce.price(range: 1_000..50_000, as_string: true)
        },
        previousAmount: {
          description: "Player's balance before the admin modification",
          placeholder: Faker::Commerce.price(range: 10_000..100_000, as_string: true)
        },
        newAmount: {
          description: "Player's final balance after the modification",
          placeholder: Faker::Commerce.price(range: 15_000..150_000, as_string: true)
        }
      }
    }
  end
end
