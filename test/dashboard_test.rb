require "test_helper"

class DashboardTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
    @user = RailsNewadmin::AdminUser.create!(email_address: "dashboard@example.test", password: "twelve words password", staff: true, superuser: true)
    @organization = Organization.create!(name: "Dashboard")
    AdminProfile.create!(admin_user: @user, organization: @organization)
    Article.create!(title: "Visible", organization: @organization, status: "published")
    Article.create!(title: "Hidden", organization: Organization.create!(name: "Hidden"), status: "draft")
  end

  test "default dashboard aggregates authorized scopes only" do
    login_admin(@user)
    assert_response :success
    assert_select "[data-resource=articles] .newadmin-metric-value", text: "1"
    assert_select "script[src*=charts]", count: 0
  end

  test "provider runs only after all declared permissions succeed" do
    original = RailsNewadmin.configuration.dashboard_provider
    RailsNewadmin.configuration.dashboard_provider = "EditorialDashboard"
    login_admin(@user)
    assert_select "[data-controller='newadmin-chart']"
    assert_select "table caption", text: "Artículos por estado"
    @user.update!(superuser: false)
    get "/admin/"
    assert_select "[data-controller='newadmin-chart']", count: 0
  ensure
    RailsNewadmin.configuration.dashboard_provider = original
  end
end
