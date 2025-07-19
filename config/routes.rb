# frozen_string_literal: true

Rails.application.routes.draw do
  # Devise shit
  devise_for :users, class_name: "ESM::User", controllers: {omniauth_callbacks: "callbacks"}
  devise_scope :user do
    delete :logout, to: "devise/sessions#destroy", as: :logout
  end

  # /
  root "home#index"

  # /communities
  resources :communities

  # /discover
  resources :discoveries, only: [:index]

  # /docs
  resources :docs, only: [] do
    collection do
      get :commands
      get :getting_started
      get :player_setup
      get :server_setup
    end
  end

  # /downloads/@esm/latest
  get "downloads/@esm/latest",
    to: redirect("https://github.com/itsthedevman/esm_arma/releases/latest"),
    as: :latest_download

  # /guides
  resources :guides, only: [] do
    collection do
      get :gambling
      get :player_notifications
      get :server_notifications
    end
  end

  # /invite
  get :invite, to: redirect("https://discordapp.com/api/oauth2/authorize?client_id=417847994197737482&permissions=125952&redirect_uri=https%3A%2F%2Fwww.esmbot.com&scope=bot")

  # /join
  get :join, to: redirect("https://discord.gg/28Ttc2s")

  # /register
  get :register, to: "user_controller#index"

  # /up
  get :up, to: "rails/health#show", as: :rails_health_check
end
