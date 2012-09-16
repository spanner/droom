Droom::Engine.routes.draw do
  
  match '/' => DAV4Rack::Handler.new(
    :root => Rails.root.to_s, 
    :root_uri_path => '/',
    :resource_class => Droom::DavResource,
    :log_to => (Rails.root + 'log/dav.log').to_s
  ), :anchor => false, :constraints => { :subdomain => "dav" }

  resources :events, :documents, :people do
    get "search", :on => :collection
  end
  
  match "/library" => 'documents#index', :as => :library
  match "/directory" => 'people#index', :as => :directory
  match "/calendar" => 'events#index', :as => :directory
  root :to => 'events#dashboard'
  
end
