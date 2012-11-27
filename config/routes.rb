Droom::Engine.routes.draw do
  
  match '/' => DAV4Rack::Handler.new(
    :root => Rails.root.to_s, 
    :root_uri_path => '/',
    :resource_class => Droom::DavResource,
    :log_to => [(Rails.root + 'log/dav.log').to_s, Logger::DEBUG]
  ), :anchor => false, :constraints => { :subdomain => Droom.dav_subdomain }

  resources :events do
    resources :invitations
    resources :group_invitations
    get "calendar", :on => :collection
    resources :documents
    collection do
      match "feed/:auth_token.:format" => "events#feed", :as => :feed
    end
  end
  
  resources :people do
    resources :events do
      collection do
        match "feed/:auth_token.:format" => "events#feed", :as => :feed
      end
    end
  end
  
  resources :documents do
    resources :document_attachments
  end
  
  resources :groups do
    resources :memberships
  end
  
  resources :venues
  resources :pages
  
  
  match "/library" => 'documents#index', :as => :library
  match "/directory" => 'people#index', :as => :directory
  match "/calendar" => 'events#index', :as => :calendar
  match "/map" => 'venues#index', :as => :map
  match "/me" => 'dashboard#index', :as => :dashboard
  match '/help/:slug', :to => 'pages#show', :as => 'help_page'
  match '/help', :to => 'pages#index', :as => 'help'
  
  match '/suggestions', :to => 'suggestions#index', :as => "suggestions", :defaults => {:format => 'json'}, :constraints => {:format => /json/}
  match '/suggestions/:type', :to => 'suggestions#index', :defaults => {:format => 'json'}, :constraints => {:format => /json/}
  
end
