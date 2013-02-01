Rails.application.routes.draw do
  mount Droom::Engine => "/", :as => :droom
end
