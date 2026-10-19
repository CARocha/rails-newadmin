require "test_helper"

class AccessManagementTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
    @admin = RailsNewadmin::AdminUser.create!(email_address: "owner@example.test", password: "twelve words password", staff: true, superuser: true)
    login_admin(@admin)
  end

  test "access pages are separate from ordinary resource permissions" do
    get "/admin/groups"
    assert_response :success
    @admin.update!(superuser: false)
    get "/admin/groups"
    assert_response :forbidden
  end

  test "a group can grant view without granting update" do
    RailsNewadmin::Permission.sync!
    view = RailsNewadmin::Permission.find_by!(resource_key: "articles", action: "view")
    get "/admin/groups/new"
    csrf_request :post, "/admin/groups", params: { group: { name: "Reviewers", permission_ids: [view.id] } }
    assert_response :see_other
    group = RailsNewadmin::Group.find_by!(name: "Reviewers")
    assert_equal [view.id], group.permissions.pluck(:id)
  end

  test "access service cannot remove the final active superuser" do
    assert_raises(RailsNewadmin::AccessManagement::LastSuperuser) do
      RailsNewadmin::AccessManagement.new(@admin).update_user!(@admin, { active: false })
    end
    assert @admin.reload.active?
    other = RailsNewadmin::AdminUser.create!(email_address: "other-owner@example.test", password: "twelve words password", staff: true, superuser: true)
    RailsNewadmin::AccessManagement.new(other).update_user!(@admin, { active: false })
    refute @admin.reload.active?
  end

  test "unknown permission IDs are rejected instead of silently accepted" do
    get "/admin/groups/new"
    csrf_request :post, "/admin/groups", params: { group: { name: "Invalid", permission_ids: [99_999_999] } }
    assert_response :unprocessable_entity
    refute RailsNewadmin::Group.exists?(name: "Invalid")
  end
end
