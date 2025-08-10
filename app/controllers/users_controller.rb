# frozen_string_literal: true

class UsersController < AuthenticatedController
  skip_before_action :authenticate_user!
  before_action :authenticate_user!, except: :register

  def edit
  end

  # def transfer_account
  #   if session[:transfer_steam_account].blank?
  #     flash[:alert] = "You are not authorized to view that page"
  #     return redirect_to root_path
  #   end

  #   steam_uid = session[:transfer_steam_account]

  #   # Remove it immediately
  #   session.delete(:transfer_steam_account)

  #   # Unset all users with this steam_uid
  #   User.where(steam_uid:).update_all(steam_uid: "")

  #   # Transfer this uid to the new user and refresh their data
  #   current_user.update!(steam_uid:)

  #   flash[:success] = {
  #     title: "Welcome #{current_user.steam_data.username}!",
  #     message: "You are now registered with ESM<br/>We've sent you a message via Discord to help you get started",
  #     hide_after: 8000
  #   }

  #   ESM.send_message(
  #     channel_id: current_user.discord_id,
  #     message: {
  #       author: {
  #         name: current_user.steam_data.username,
  #         icon_url: current_user.steam_data.avatar
  #       },
  #       title: "Successfully Registered!",
  #       description: "You have been registered with Exile Server Manager. This allows you to use ESM on any server running ESM that you join. You don't even have to be in their Discord!\n**Below is some important information to get you started.**",
  #       color: ESM::COLORS::GREEN,
  #       fields: [{
  #         name: "Getting Started",
  #         value: "First time using ESM or need a refresher? Come read the [Getting Started](https://www.esmbot.com/wiki) article to help get you acquainted"
  #       }, {
  #         name: "Commands",
  #         value: "Need to feel powerful? Check out my [commands](https://www.esmbot.com/wiki/commands) and come back to show off your new found knowledge!"
  #       }]
  #     }
  #   )

  #   redirect_to edit_user_path(current_user.discord_id)
  # end

  # def cancel_transfer
  #   session.delete(:transfer_steam_account)
  #   render json: {}
  # end

  def destroy
    raise "destroy"
    # return redirect_to root_path if !current_user

    # if current_user.destroy
    #   sign_out(current_user)
    #   flash[:success] = "Your account has been deleted"
    # else
    #   flash[:alert] = {
    #     title: "Well... This is awkward",
    #     message: "We failed to delete your account, please join our Discord and notify a developer so we can take care of it for you.",
    #     hide_after: 8000
    #   }
    # end

    # redirect_to root_path
  end

  def register
    raise "Register"
    # session[:registering] = true
    # render "layouts/oauth_login", locals: {url: user_discord_omniauth_authorize_path}
  end

  def deregister
    raise "Deregister"
    # return redirect_to root_path if !current_user

    # current_user.deregister!

    # flash[:success] = "You've been deregistered.<br/>You can reregister via the Sign into Steam button"
    # redirect_to edit_user_path(current_user.discord_id)
  end
end
