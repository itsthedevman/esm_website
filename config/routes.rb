# frozen_string_literal: true

Rails.application.routes.draw do
  # Devise shit
  devise_for :users, class_name: "ESM::User", controllers: {omniauth_callbacks: "oauth"}
  devise_scope :user do
    # /login
    get :login, to: "oauth#login"

    # /logout
    delete :logout, to: "devise/sessions#destroy", as: :logout
  end

  direct :discord_markdown_docs do
    "https://support.discord.com/hc/en-us/articles/210298617-Markdown-Text-101-Chat-Formatting-Bold-Italic-Underline"
  end

  ##################################################################################################

  # /
  root "home#index"

  # /account
  resource :users, only: %i[edit update destroy], path: "account" do
    collection do
      get :deregister
      # post "cancel_transfer"
      # get "transfer_account"
    end

    # /account/notification_routing
    resources :user_notification_routes,
      path: :notification_routing,
      as: :notification_routing,
      only: %i[create update destroy] do
      collection do
        get :/, action: :player_index

        patch :accept_requests
        patch :decline_requests

        put :accept_all_requests
        put :decline_all_requests

        delete :destroy_many
      end
    end
  end

  # /communities
  resources :communities, param: :community_id do
    # /communities/:community_id/commands
    resources :commands, only: %i[index update], param: :name

    # /communities/:community_id/logs/:log_id
    resources :logs, only: [:show], param: :log_id

    # /communities/:community_id/notifications
    resources :notifications, param: :notification_id, except: [:show]

    # /communities/:community_id/servers
    resources :servers, param: :server_id do
      member do
        get :key # V1
        get :server_config
        get :server_token
        patch :disable_v2
        patch :enable_v2
      end
    end

    # /communities/:community_id/notification_routing
    resources :user_notification_routes,
      path: "notification_routing",
      as: "notification_routing",
      only: %i[create update destroy] do
      collection do
        get :/, action: :server_index
        patch "accept_requests"
        patch "decline_requests"

        put "accept_all_requests"
        put "decline_all_requests"

        delete :destroy_many
      end
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
  get :invite, to: redirect(ESM.bot.invite_url)

  # /join
  get :join, to: redirect("https://discord.gg/28Ttc2s")

  # /legal
  resource :legal, only: [] do
    collection do
      get :privacy_policy
      get :terms_of_service
    end
  end

  # /register
  get :register, to: redirect("/account/edit")

  # /requests
  resources :requests, only: [] do
    member do
      # /requests/:id/accept
      get "accept"

      # /requests/:id/decline
      get "decline"
    end
  end

  # /tools
  resource :tools, only: [] do
    get :rpt_parser
  end

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
#   member do
#     get "can_change_id"
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
