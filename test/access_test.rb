require "test_helper"

class AccessTest < ActiveSupport::TestCase
  def setup
    @reader = RailsNewadmin::AdminUser.create!(email_address: "reader@example.test", password: "twelve words password", staff: true)
    @resource = Class.new(RailsNewadmin::Resource) do
      model "Article"
      key "articles"
      permit :title
    end
  end

  test "grants require active staff and an explicit group permission" do
    access = RailsNewadmin::Access.new(@reader, @resource)
    refute access.granted?(:view)
    group = RailsNewadmin::Group.create!(name: "Readers")
    group.admin_users << @reader
    permission = RailsNewadmin::Permission.create!(resource_key: "articles", action: "view")
    group.permissions << permission
    assert access.granted?(:view)
    refute access.granted?(:update)
    group.permissions.delete(permission)
    refute access.granted?(:view)
    @reader.update!(superuser: true)
    assert access.granted?(:view)
    @reader.update!(active: false)
    refute access.granted?(:view)
  end

  test "default policy remains closed even to superusers" do
    @reader.update!(superuser: true)
    access = RailsNewadmin::Access.new(@reader, @resource)
    refute access.allowed?(:view)
    assert_empty access.policy.permitted_attributes(actor: @reader, action: :create, record: nil)
  end

  test "permission synchronization is explicit idempotent and deactivates orphaned grants" do
    registry = RailsNewadmin::Registry.new([@resource])
    2.times { RailsNewadmin::Permission.sync!(registry) }
    assert_equal 4, RailsNewadmin::Permission.where(resource_key: "articles", active: true).count
    RailsNewadmin::Permission.sync!(RailsNewadmin::Registry.new)
    assert_equal 0, RailsNewadmin::Permission.where(active: true).count
  end
end
