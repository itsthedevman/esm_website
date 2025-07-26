# frozen_string_literal: true

Rails.application.routes.draw do
  # Devise shit
  devise_for :users, class_name: "ESM::User", controllers: {omniauth_callbacks: "oauth"}
  devise_scope :user do
    delete :logout, to: "devise/sessions#destroy", as: :logout
  end

  direct :discord_markdown_docs do
    "https://support.discord.com/hc/en-us/articles/210298617-Markdown-Text-101-Chat-Formatting-Bold-Italic-Underline"
  end

  ##################################################################################################

  # /
  root "home#index"

  # /communities
  resources :communities, param: :community_id do
    resources :servers, param: :server_id do
      # member do
      #   get "key" # V1
      #   get "server_token"
      #   get "server_config"
      #   patch :enable_v2
      #   patch :disable_v2
      # end
    end
  end

  # /discover
  resource :discover, only: [:show]

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

# # Custom error routes
# match "/404", to: "errors#not_found", via: :all
# match "/500", to: "errors#internal_server_error", via: :all

# # Redirects
# get "/portal/server", to: redirect("/communities")
# get "player_dashboard", to: redirect("/account")
# get "server_dashboard", to: redirect("/communities")

# # Auth
# get "login", to: "index#login"
# get "register", to: "users#register"
# post "link/steam", to: "users#authorize_steam"

# # Logs
# get "logs/:id(/:entry_id)", to: "logs#show", as: :log

# # Requires authentication routes below!
# resources :communities, only: %i[index edit update destroy] do
#   resources :commands, only: %i[index update], param: :name
#   resources :notifications, only: %i[index create update destroy]
#   resources :user_notification_routes, path: "notification_routing", as: "notification_routing", only: %i[create update destroy] do
#     collection do
#       get "/", action: :server_index
#       patch "accept_requests"
#       patch "decline_requests"

#       put "accept_all_requests"
#       put "decline_all_requests"

#       delete :destroy_many
#     end
#   end

#   member do
#     get "can_change_id"
#   end
# end

# resources :users, only: %i[edit destroy] do
#   member do
#     post "cancel_transfer"
#     get "transfer_account"
#     get "deregister"
#   end

#   ###

#   resources :user_notification_routes,
#     path: "notification_routing",
#     as: "notification_routing",
#     only: %i[create update destroy] do
#     collection do
#       get "/", action: :player_index

#       patch "accept_requests"
#       patch "decline_requests"

#       put "accept_all_requests"
#       put "decline_all_requests"

#       delete :destroy_many
#     end
#   end

#   resources :user_aliases, path: "aliases", as: "aliases", only: [:create, :update, :destroy]

#   resources :user_defaults, path: "defaults", as: "defaults", only: [] do
#     patch "/", action: :update, on: :collection
#   end
# end

# resources :requests, only: [] do
#   member do
#     # Totally the wrong verb here, but I can't use put since it's from Discord
#     get "accept"
#     get "decline"
#   end
# end

# # API
# namespace :api do
#   scope :v1 do
#     match "users", to: "users#index", via: [:get, :post] # /api/v1/users?discord_ids=IDS

#     resources :users, param: :discord_id, only: [
#       :show # /api/v1/users/:discord_id
#     ]
#   end
# end
