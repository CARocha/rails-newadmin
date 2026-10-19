RailsNewadmin::Engine.routes.draw do
  root to: "dashboard#index"
  resource :session, only: [:new, :create, :destroy]
end
