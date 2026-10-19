Rails.application.routes.draw do
  mount RailsNewadmin::Engine => "/admin", as: :rails_newadmin
  get "/host", to: ->(_env) { [ 200, { "content-type" => "text/plain" }, [ "Host application" ] ] }
end
