Droom::Engine.routes.draw do
  
  match '/' => DAV4Rack::Handler.new(
    :root => Rails.root.to_s, 
    :root_uri_path => '/',
    :resource_class => Droom::DavResource,
    :log_to => [(Rails.root + 'log/dav.log').to_s, Logger::DEBUG]
  ), :anchor => false, :constraints => { :subdomain => "dav" }

  resources :events do
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
  
  resources :venues
  resources :documents
  
  match "/library" => 'documents#index', :as => :library
  match "/directory" => 'people#index', :as => :directory
  match "/calendar" => 'events#index', :as => :calendar
  
  match '/suggestions', :to => 'suggestions#index', :as => "suggestions"
  match '/suggestions/:type', :to => 'suggestions#index'
  
  root :to => 'events#dashboard'
  
end
