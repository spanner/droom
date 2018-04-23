Droom::Engine.routes.draw do

  root to: "dashboard#index"
  get "/dashboard" => "dashboard#index", :as => :dashboard

  match '/suggestions'  => 'suggestions#index', as: "suggestions", via: [:get, :options]
  match '/suggestions/:type'  => 'suggestions#index', via: [:get, :options]

  namespace :api, defaults: {format: 'json'}, constraints: {format: /(json|xml)/} do
    resources :users do
      post 'reindex', on: :member, as: :reindex
      get "whoami" , on: :collection, as: :whoami
    end
    resources :events
    resources :venues
    resources :images
    resources :videos
    resources :pages
    resources :tags
    resources :organisations do
      post :register, on: :collection
    end
  end

  resources :helps

  resources :pages do
    put :publish, on: :member
  end

  resources :services do
    resources :permissions
  end

  resources :preferences
  resources :invitations
  resources :memberships
  resources :scraps
  resources :enquiries do
    get "test", on: :collection
  end

  resources :calendars, only: [:show]
  resources :events do
    get "calendar", on: :collection
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
  end

  resources :documents do
    get "suggest", on: :collection
    put "reposition", on: :member
  end

  resources :folders do
    get "dropbox", on: :member, as: :dropbox
    resources :documents
    resources :folders
  end

  resources :organisations do
    resources :users
    collection do
      get :signup
      post :register
      get :pending
    end
    member do
      get :approve
      get :disapprove
    end
  end

  resources :users do
    get "activity" => "users#activity", as: :activity
    get :preferences, on: :member, as: :preferences
    put :preference, on: :member, as: :set_preference
    put :set_password, on: :collection
    put :reinvite, on: :member
    put "/subsume/:other_id" => "users#subsume", as: 'subsume'
    resources :events
    resources :emails
    resources :phones
    resources :addresses
  end

  resources :groups do
    resources :memberships
    resources :group_permissions
  end

  resources :event_types
  resources :venues

  resources :dropbox_tokens do
    get "/register", on: :collection, action: :create
  end

  put "/set_password" => "users#set_password", as: :set_my_password
  get "/enquire" => "enquiries#new", as: :enquire
  get "/noticeboard" => "scraps#index", as: :noticeboard
  get "/profile" => "users#edit", as: :profile, defaults: {view: "profile"}
  get "/page/:slug" => "pages#published", as: :published_page, defaults: {format: "html"}
  get "/signup" => "organisations#signup", as: :signup

end
