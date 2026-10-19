RailsNewadmin.configure { |config| config.dashboard_provider = "EditorialDashboard" } if ENV["NEWADMIN_DEMO_DASHBOARD"] == "1"
