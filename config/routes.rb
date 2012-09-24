Droom::Engine.routes.draw do
  
  match '/' => DAV4Rack::Handler.new(
    :root => Rails.root.to_s, 
    :root_uri_path => '/',
    :resource_class => Droom::DavResource,
    :log_to => [(Rails.root + 'log/dav.log').to_s, Logger::DEBUG]
  ), :anchor => false, :constraints => { :subdomain => "dav" }

  resources :events, :people, :venues, :documents
  
  match "/library" => 'documents#index', :as => :library
  match "/directory" => 'people#index', :as => :directory
  match "/calendar" => 'events#index', :as => :calendar
  match "/map" => 'venues#index', :as => :map
  
  match '/suggestions', :to => 'suggestions#index', :as => "suggestions"
  match '/suggestions/:type', :to => 'suggestions#index'
  
  root :to => 'events#dashboard'
  
end
