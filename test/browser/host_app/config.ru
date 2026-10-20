require_relative "config/environment"
map ENV.fetch("NAVIGATION_PREFIX", "/") do
  run Rails.application
end
Rails.application.load_server
