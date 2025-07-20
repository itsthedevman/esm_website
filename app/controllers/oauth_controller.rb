# frozen_string_literal: true

class OAuthController < Devise::OmniauthCallbacksController
  skip_before_action :verify_authenticity_token, only: [:steam, :discord]

  def discord
    user = ESM::User.from_omniauth(request.env["omniauth.auth"])
    sign_in_and_redirect user
  end

  def steam
    return redirect_to root_path if !current_user

    if current_user.registered?
      flash[:alert] = {
        title: "Your Discord is already linked to Steam",
        message: "If you would like to change your Steam account, click the 'Deregister' button",
        hide_after: 7000
      }
      return redirect_to edit_user_path(current_user.discord_id)
    end

    steam_info = request.env["omniauth.auth"]

    if User.exists?(steam_uid: steam_info[:uid])
      session[:transfer_steam_account] = steam_info[:uid]
      return redirect_to edit_user_path(current_user.discord_id, already_registered: true)
    end

    current_user.update(steam_uid: steam_info[:uid])

    flash[:success] = {
      title: "Welcome #{current_user.steam_data.username}!",
      message: "You are now registered with ESM<br/>We've sent you a message via Discord to help you get started",
      hide_after: 8000
    }

    ESM.send_message(
      channel_id: current_user.discord_id,
      message: {
        author: {
          name: current_user.steam_data.username,
          icon_url: current_user.steam_data.avatar
        },
        title: "Successfully Registered!",
        description: "You have been registered with Exile Server Manager. This allows you to use ESM on any server running ESM that you join. You don't even have to be in their Discord!\n**Below is some important information to get you started.**",
        color: ESM::COLORS::GREEN,
        fields: [{
          name: "Getting Started",
          value: "First time using ESM or need a refresher? Come read the [Getting Started](https://www.esmbot.com/wiki) article to help get you acquainted"
        }, {
          name: "Commands",
          value: "Need to feel powerful? Check out my [commands](https://www.esmbot.com/wiki/commands) and come back to show off your new found knowledge!"
        }]
      }
    )

    redirect_to edit_user_path(current_user.discord_id)
  end

  def failure
    redirect_to root_path
  end
end
