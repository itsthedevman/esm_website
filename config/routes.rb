# frozen_string_literal: true

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  # /
  root "home#index"

  devise_for :users, class_name: "ESM::User", controllers: {omniauth_callbacks: "callbacks"}
  devise_scope :user do
    delete "logout", to: "devise/sessions#destroy", as: :logout
  end

  # /join
  get "join", to: redirect("https://discord.gg/28Ttc2s")

  # /invite
  get "invite", to: redirect("https://discordapp.com/api/oauth2/authorize?client_id=417847994197737482&permissions=125952&redirect_uri=https%3A%2F%2Fwww.esmbot.com&scope=bot")

  # /docs
  resources :docs, only: [] do
    collection do
      get :getting_started
      get :commands
    end
  end

  # /guides
  resources :guides, only: [] do
    collection do
      get :gambling
      get :player_notifications
      get :server_notifications
    end
  end
end
