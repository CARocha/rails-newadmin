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
    csrf_request :post, "/admin/groups", params: { group: { name: "Reviewers", permission_ids: [ view.id ] } }
    assert_response :see_other
    group = RailsNewadmin::Group.find_by!(name: "Reviewers")
    assert_equal [ view.id ], group.permissions.pluck(:id)
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
    csrf_request :post, "/admin/groups", params: { group: { name: "Invalid", permission_ids: [ 99_999_999 ] } }
    assert_response :unprocessable_entity
    refute RailsNewadmin::Group.exists?(name: "Invalid")
  end

  test "owners create accounts assign groups and edit without exposing password digests" do
    group = RailsNewadmin::Group.create!(name: "Account readers")
    get "/admin/admin_users/new"
    assert_response :success
    csrf_request :post, "/admin/admin_users", params: { admin_user: { email_address: "new@example.test", password: "another secure password", password_confirmation: "another secure password", active: "1", staff: "1", group_ids: [ group.id ] } }
    assert_response :see_other
    user = RailsNewadmin::AdminUser.find_by!(email_address: "new@example.test")
    assert_equal [ group.id ], user.group_ids
    get "/admin/admin_users/#{user.id}/edit"
    assert_response :success
    assert_select "input[name*=password_digest]", count: 0
    csrf_request :patch, "/admin/admin_users/#{user.id}", params: { admin_user: { locale: "en", active: "1", staff: "1" } }
    assert_equal "en", user.reload.locale
    get "/admin/admin_users"
    assert_response :success
    assert_includes response.body, user.email_address
    get "/admin/admin_users/#{@admin.id}/edit"
    csrf_request :patch, "/admin/admin_users/#{@admin.id}", params: { admin_user: { active: "0" } }
    assert_response :unprocessable_entity
    assert @admin.reload.active?
  end

  test "privileged access managers cannot edit superusers or create new owners" do
    group = RailsNewadmin::Group.create!(name: "Access managers")
    group.permissions << RailsNewadmin::Permission.create!(resource_key: "admin_access", action: "manage_access")
    manager = RailsNewadmin::AdminUser.create!(email_address: "manager@example.test", password: "twelve words password", staff: true)
    group.admin_users << manager
    login_admin(manager)
    get "/admin/groups"
    assert_response :success
    get "/admin/admin_users/#{@admin.id}/edit"
    csrf_request :patch, "/admin/admin_users/#{@admin.id}", params: { admin_user: { active: "0" } }
    assert_response :forbidden
    assert @admin.reload.active?
    get "/admin/admin_users/new"
    csrf_request :post, "/admin/admin_users", params: { admin_user: { email_address: "unprivileged@example.test", password: "another secure password", password_confirmation: "another secure password", active: "1", staff: "1", superuser: "1" } }
    assert_response :see_other
    refute RailsNewadmin::AdminUser.find_by!(email_address: "unprivileged@example.test").superuser?
  end

  test "group changes remain explicit and validation errors do not discard old grants" do
    RailsNewadmin::Permission.sync!
    permission = RailsNewadmin::Permission.find_by!(resource_key: "articles", action: "view")
    group = RailsNewadmin::Group.create!(name: "Editable")
    group.permissions << permission
    get "/admin/groups/#{group.id}/edit"
    assert_response :success
    csrf_request :patch, "/admin/groups/#{group.id}", params: { group: { name: "Renamed", permission_ids: [ permission.id ] } }
    assert_response :see_other
    assert_equal "Renamed", group.reload.name
    get "/admin/groups/#{group.id}/edit"
    csrf_request :patch, "/admin/groups/#{group.id}", params: { group: { name: "", permission_ids: [] } }
    assert_response :unprocessable_entity
    assert_equal [ permission.id ], group.reload.permission_ids
  end
  test "a manager cannot change an account promoted after it was loaded" do
    group = RailsNewadmin::Group.create!(name: "Managers")
    group.permissions << RailsNewadmin::Permission.create!(resource_key: "admin_access", action: "manage_access")
    manager = RailsNewadmin::AdminUser.create!(email_address: "manager-race@example.test", password: "twelve words password", staff: true)
    group.admin_users << manager
    target = RailsNewadmin::AdminUser.create!(email_address: "promoted@example.test", password: "twelve words password", staff: true)
    stale = RailsNewadmin::AdminUser.find(target.id)
    RailsNewadmin::AccessManagement.new(@admin).update_user!(target, { superuser: true })
    assert_raises(RailsNewadmin::AccessDenied) do
      RailsNewadmin::AccessManagement.new(manager).update_user!(stale, { password: "attacker chosen password" })
    end
    assert target.reload.authenticate("twelve words password")
  end
  test "service rejects unauthorized actors unknown fields and invalid membership atomically" do
    assert_raises(RailsNewadmin::AccessDenied) { RailsNewadmin::AccessManagement.new(nil) }
    ordinary = RailsNewadmin::AdminUser.create!(email_address: "ordinary@example.test", password: "twelve words password", staff: true)
    assert_raises(RailsNewadmin::AccessDenied) { RailsNewadmin::AccessManagement.new(ordinary) }
    service = RailsNewadmin::AccessManagement.new(@admin)
    assert_raises(ArgumentError) { service.update_user!(ordinary, { password_digest: "injected" }) }
    assert_raises(RailsNewadmin::AccessDenied) do
      service.update_user!(ordinary, { locale: "en", group_ids: [ 99_999_999 ] })
    end
    assert_nil ordinary.reload.locale
    assert_empty RailsNewadmin::AuditEvent.where(record_id: ordinary.id.to_s)
    group = RailsNewadmin::Group.create!(name: "Explicit managers")
    group.permissions << RailsNewadmin::Permission.create!(resource_key: "admin_access", action: "manage_access")
    group.admin_users << ordinary
    assert_raises(RailsNewadmin::AccessDenied) do
      RailsNewadmin::AccessManagement.new(ordinary).update_user!(@admin, { superuser: false })
    end
  end
end
