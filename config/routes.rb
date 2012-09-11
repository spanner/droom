Droom::Engine.routes.draw do
  root :to => 'events#index'
  
  resources :events 
  resources :documents
  resources :people
  
  match "/library" => 'documents#index', :as => :library
  match "/directory" => 'people#index', :as => :directory
end
