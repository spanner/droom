Droom::Engine.routes.draw do
  
  match '/' => DAV4Rack::Handler.new(
    :root => Rails.root.to_s, 
    :root_uri_path => '/',
    :resource_class => Droom::DavResource,
    :log_to => [(Rails.root + 'log/dav.log').to_s, Logger::DEBUG]
  ), :anchor => false, :constraints => { :subdomain => Droom.dav_subdomain }

  devise_for :users, :class_name => 'Droom::User', :module => :devise, :controllers => {:confirmations => 'droom/confirmations'}

  # intermediate confirmation step to allow invitation without setting a password
  devise_scope :user do
    put "/confirm_password" => "confirmations#update", :as => :confirm_password
  end

  resources :users do
    # member do
    #   put :conceal
    #   put :reveal
    # end
  end
  resources :documents
  resources :preferences
  resources :calendars
  resources :invitations

  resources :scraps do
    collection do
      match "feed/:auth_token.:format" => "scraps#index", :as => :feed
    end
  end

  resources :events do
    resources :invitations
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
    resources :people
  end
  
  resources :people do
    get "invite", :on => :member, :as => :invite
    resources :events do
      collection do
        match "feed/:auth_token.:format" => "events#index", :as => :feed
      end
    end
  end
  
  resources :groups do
    resources :memberships
  end
  
  resources :venues
  resources :pages

  resources :dropbox_tokens do
    get "/register", :on => :collection, :action => :create
  end
  

  match '/help/:slug', :to => 'pages#show', :as => 'help_page'
  match '/help', :to => 'pages#index', :as => 'help'
  
  match '/search', :to => 'search#index', :as => "search"
  match '/videos.:format', :to => 'youtube#index', :as => "videos"
  match '/videos/:yt_id.:format', :to => 'youtube#show', :as => "video"
  match '/suggestions.:format', :to => 'suggestions#index', :as => "suggestions", :defaults => {:format => 'json'}
  match '/suggestions/:type.:format', :to => 'suggestions#index', :defaults => {:format => 'json'}

  root :to => "dashboard#index", :as => :dashboard
end
