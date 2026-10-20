Rails.application.routes.draw do
  resource :host_session, only: [ :new, :create, :destroy ], controller: :host_sessions
  mount RailsNewadmin::Engine => "/admin", as: :rails_newadmin
  get "/host", to: ->(_env) { [ 200, { "content-type" => "text/plain" }, [ "Host application" ] ] }
end
