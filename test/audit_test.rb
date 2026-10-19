require "test_helper"
require "minitest/mock"

class AuditTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
    @admin = RailsNewadmin::AdminUser.create!(email_address: "audit@example.test", password: "twelve words password", staff: true, superuser: true)
    organization = Organization.create!(name: "Audit")
    AdminProfile.create!(admin_user: @admin, organization: organization)
    login_admin(@admin)
  end

  test "mutation and minimal audit event commit together" do
    get "/admin/resources/articles/new"
    csrf_request :post, "/admin/resources/articles", params: { record: { title: "Audited", status: "draft" } }
    assert_response :see_other
    event = RailsNewadmin::AuditEvent.last
    assert_equal "create", event.action
    assert_equal @admin.id.to_s, event.actor_id
    assert_equal "articles", event.resource_key
    refute_includes event.attributes.to_s, "twelve words password"
    refute_includes event.attributes.to_s, "Audited"
  end

  test "audit failure rolls back business mutation" do
    get "/admin/resources/articles/new"
    RailsNewadmin::AuditEvent.stub(:record!, ->(**) { raise "audit failure" }) do
      assert_raises(RuntimeError) do
        csrf_request :post, "/admin/resources/articles", params: { record: { title: "Must roll back", status: "draft" } }
      end
    end
    refute Article.exists?(title: "Must roll back")
  end
end
