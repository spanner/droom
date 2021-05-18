Droom::Engine.routes.draw do

  root to: "dashboard#index"
  get "/dashboard" => "dashboard#index", :as => :dashboard

  match '/suggestions'  => 'suggestions#index', as: "suggestions", via: [:get, :options], defaults: {format: "json"}
  match '/suggestions/:type'  => 'suggestions#index', via: [:get, :options], defaults: {format: "json"}

  namespace :api, defaults: {format: 'json'} do
    resources :users do
      get :whoami, on: :collection, as: :whoami
      # post :inviteme, on: :collection, as: :inviteme
      post :reindex, on: :member, as: :reindex
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

  devise_for :users,
             class_name: 'Droom::User',
             module: :devise,
             skip: :registrations,
             controllers: {
               confirmations: 'droom/users/confirmations',
               sessions: 'droom/users/sessions',
               passwords: 'droom/users/passwords',
               registrations: 'droom/users/registrations'
             }

  devise_scope :user do
    get "/signup" => "users/registrations#new", as: :signup
    post '/register' => 'users/registrations#create', as: :register
    get "/users/registrations/confirm" => "users/registrations#confirm", as: :confirm_registration
    get "/users/:id/welcome/:confirmation_token" => "users/confirmations#show", as: :welcome
    patch "/users/:id/confirm" => "users/confirmations#update", as: :confirm_password

    # password reset
    get "/users/passwords/show" => "users/passwords#show", as: :show_confirmation
    get "/users/passwords/completed" => "users/passwords#completed", as: :complete_confirmation

    # login by emailed one-time link
    post '/inviteme' => 'api/users#inviteme', as: :inviteme
    get '/users/signin/:u/:t' => 'users/sessions#signmein', as: :signmein

    # droom_client authentication calls
    post '/api/users/sign_in' => 'api/sessions#create', as: :api_sign_in
    delete '/api/users/sign_out' => 'api/sessions#destroy', as: :api_sign_out
    get '/api/authenticate/:tok' => 'api/sessions#authenticate', as: 'authenticate'
    get '/api/deauthenticate/:tok' => 'api/sessions#deauthenticate', as: 'deauthenticate'
    get '/api/users/authenticable/:id' => 'api/users#authenticable', as: 'authenticable'
  end

  resources :helps

  resources :pages do
    put :publish, on: :member
  end

  resources :services do
    resources :permissions
  end

  resources :preferences
  resources :memberships
  resources :enquiries do
    get "test", on: :collection
  end

  resources :calendars, only: [:show] do
    resources :events
  end
  resources :events do
    collection do
      get :calendar
      get :past
      get "subscribe/:tok", action: "subscribe", as: :subscribe
    end
    resources :documents
  end

  resources :noticeboards do
    resources :scraps
  end
  resources :scraps

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
      get :pending
    end
    member do
      get :approve
      get :disapprove
      put :merge
    end
  end

  resources :users do
    get "activity" => "users#activity", as: :activity
    get :preferences, on: :member, as: :preferences
    put :preference, on: :member, as: :set_preference
    get :download, on: :collection
    get :admin, on: :collection
    put :setup, on: :collection
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
  put "/set_organisation" => "users#set_organisation", as: :set_my_organisation
  get "/enquire" => "enquiries#new", as: :enquire
  get "/noticeboard" => "scraps#index", as: :all_notices
  get "/profile" => "users#edit", as: :profile, defaults: {view: "profile"}

end
