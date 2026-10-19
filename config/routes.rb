RailsNewadmin::Engine.routes.draw do
  root to: "dashboard#index"
  resource :session, only: [:new, :create, :destroy]
  resource :password, only: [:new, :create, :edit, :update]
  get "resources/:resource_key/options/:association", to: "resources#options", as: :resource_options
  get "resources/:resource_key", to: "resources#index", as: :resource_records
  post "resources/:resource_key", to: "resources#create"
  get "resources/:resource_key/new", to: "resources#new", as: :new_resource_record
  get "resources/:resource_key/:id/edit", to: "resources#edit", as: :edit_resource_record
  get "resources/:resource_key/:id/delete", to: "resources#delete", as: :delete_resource_record
  get "resources/:resource_key/:id", to: "resources#show", as: :resource_record
  patch "resources/:resource_key/:id", to: "resources#update"
  put "resources/:resource_key/:id", to: "resources#update"
  delete "resources/:resource_key/:id", to: "resources#destroy"
end
