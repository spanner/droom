Droom::Engine.routes.draw do
  
  match '/' => DAV4Rack::Handler.new(
    :root => Rails.root.to_s, 
    :root_uri_path => '/',
    :resource_class => Droom::DavResource,
    :log_to => [(Rails.root + 'log/dav.log').to_s, Logger::DEBUG]
  ), :anchor => false, :constraints => { :subdomain => Droom.dav_subdomain }

  devise_for :users, :class_name => 'Droom::User', :module => :devise
  resources :users do
    get 'welcome/:auth_token', :action => :welcome, :on => :member, :as => :welcome
  end

  resources :documents
  resources :preferences
  resources :scraps

  resources :events do
    resources :invitations
    resources :group_invitations
    get "calendar", :on => :collection
    resources :documents
    collection do
      match "feed/:auth_token.:format" => "events#feed", :as => :feed
    end
  end
  
  resources :documents#, :only => [:index, :show]
  resources :folders do
    get "dropbox", :on => :member, :as => :dropbox
    resources :documents
  end
  
  resources :people do
    resources :events do
      collection do
        match "feed/:auth_token.:format" => "events#feed", :as => :feed
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
  
  match "/library" => 'folders#index', :as => :library
  match "/directory" => 'people#index', :as => :directory
  match "/calendar" => 'events#index', :as => :calendar
  match "/map" => 'venues#index', :as => :map

  match '/help/:slug', :to => 'pages#show', :as => 'help_page'
  match '/help', :to => 'pages#index', :as => 'help'
  
  match '/search', :to => 'search#index', :as => "search"
  match '/suggestions.:format', :to => 'suggestions#index', :as => "suggestions", :defaults => {:format => 'json'}
  match '/suggestions/:type.:format', :to => 'suggestions#index', :defaults => {:format => 'json'}

  root :to => "dashboard#index", :as => :dashboard
end
