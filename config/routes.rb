Droom::Engine.routes.draw do 
  
  devise_for :users, :class_name => 'Droom::User', :module => :devise, :controllers => {:confirmations => 'droom/confirmations'}

  # intermediate confirmation step to allow invitation without setting a password
  devise_scope :user do
    get "/users/:id/welcome/:confirmation_token" => "user_confirmations#show", :as => :welcome
    put "/users/:id/confirm" => "user_confirmations#update", :as => :confirm_password
  end

  resources :users do
    get "preferences", :on => :member, :as => :preferences
  end

  resources :documents
  resources :preferences
  resources :permissions
  resources :services
  resources :calendars
  resources :invitations
  resources :memberships

  resources :scraps do
    collection do
      match "feed/:auth_token.:format" => "scraps#index", :as => :feed
    end
  end

  resources :events do
    resources :invitations do
      member do
        put :accept
        put :refuse
        put :toggle
      end
    end
    resources :group_invitations
    resources :documents
    resources :agenda_categories
    collection do
      get "calendar"
      match "feed/:auth_token.:format" => "events#feed", :as => :feed
    end
  end
  
  resources :documents#, :only => [:index, :show]
  resources :folders do
    get "dropbox", :on => :member, :as => :dropbox
    resources :documents
    resources :folders
  end
  
  resources :organisations do
    resources :users
  end
  
  resources :users do
    get "invite", :on => :member, :as => :invite
    resources :events do
      collection do
        match "feed/:auth_token.:format" => "events#index", :as => :feed
      end
    end
  end
  
  resources :groups do
    resources :memberships
    resources :users
    resources :group_permissions
  end
  
  resources :venues
  resources :pages

  resources :dropbox_tokens do
    get "/register", :on => :collection, :action => :create
  end
  

  match '/help/:slug', :to => 'pages#show', :as => 'help_page'
  match '/help', :to => 'pages#index', :as => 'help'
  
  match '/videos.:format', :to => 'youtube#index', :as => "videos"
  match '/videos/:yt_id.:format', :to => 'youtube#show', :as => "video"
  match '/suggestions.:format', :to => 'suggestions#index', :as => "suggestions", :defaults => {:format => 'json'}
  match '/suggestions/:type.:format', :to => 'suggestions#index', :defaults => {:format => 'json'}

  root :to => "dashboard#index", :as => :dashboard
end
