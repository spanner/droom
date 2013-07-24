Droom::Engine.routes.draw do 
  root :to => "dashboard#index", :as => :dashboard

  get '/help/:slug' => 'pages#show', :as => 'help_page'
  get '/help' => 'pages#index', :as => 'help'
  get '/videos.:format' => 'youtube#index', :as => "videos"
  get '/videos/:yt_id.:format' => 'youtube#show', :as => "video"
  get '/suggestions.:format'  => 'suggestions#index', :as => "suggestions", :defaults => {:format => 'json'}
  get '/suggestions/:type.:format'  => 'suggestions#index', :defaults => {:format => 'json'}

  devise_for :users, :class_name => 'Droom::User', :module => :devise, :controllers => {:confirmations => 'droom/confirmations'}
  
  # intermediate confirmation step to allow invitation without setting a password
  devise_scope :user do
    get "/users/:id/welcome/:confirmation_token" => "user_confirmations#show", :as => :welcome
    put "/users/:id/confirm" => "user_confirmations#update", :as => :confirm_password
  end

  resources :services do
    resources :permissions
  end

  resources :documents
  resources :preferences
  resources :calendars
  resources :invitations
  resources :memberships

  resources :scraps do
    collection do
      get "feed/:auth_token.:format" => "scraps#index", :as => :feed
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
      get "feed/:auth_token.:format" => "events#feed", :as => :feed
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
    get "preferences", :on => :member, :as => :preferences
    resources :events do
      collection do
        get "feed/:auth_token.:format" => "events#index", :as => :feed
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

end
