RailsNewadmin.configure { |config| config.dashboard_provider = "EditorialDashboard" } if ENV["NEWADMIN_DEMO_DASHBOARD"] == "1"
if ENV["NEWADMIN_DEMO_HOST_AUTH"] == "1"
  RailsNewadmin.configure do |config|
    config.authentication = :host
    config.authentication_adapter = "ExistingLoginAdapter"
  end
end
