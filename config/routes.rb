Droom::Engine.routes.draw do
  
  match '/' => DAV4Rack::Handler.new(
    :root => Rails.root.to_s, 
    :root_uri_path => '/',
    :resource_class => Droom::DavResource,
    :log_to => [(Rails.root + 'log/dav.log').to_s, Logger::DEBUG]
  ), :anchor => false, :constraints => { :subdomain => "dav" }

  resources :events, :documents, :people, :venues
  
  match "/library" => 'documents#index', :as => :library
  match "/directory" => 'people#index', :as => :directory
  match "/calendar" => 'events#index', :as => :directory
  
  match '/suggestions', :to => 'suggestions#index', :as => "suggestions"
  match '/suggestions/:type', :to => 'suggestions#index'
  
  root :to => 'events#dashboard'
  
end
