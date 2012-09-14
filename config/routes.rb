Droom::Engine.routes.draw do
  
  match '/' => DAV4Rack::Handler.new(
    :root => Rails.root.to_s, 
    :root_uri_path => '/',
    :resource_class => Droom::DavResource
  ), :anchor => false, :constraints => { :subdomain => "dav" }

  resources :events 
  resources :documents
  resources :people
  
  match "/library" => 'documents#index', :as => :library
  match "/directory" => 'people#index', :as => :directory
  match "/calendar" => 'events#index', :as => :directory
  root :to => 'events#dashboard'
  
end
