require "test_helper"

class IncompleteHostAdapter < RailsNewadmin::HostAuthenticationAdapter; end
class HiddenHostAdapter < ExistingLoginAdapter
  private :current_user
end
class UndefinedHostAdapter < ExistingLoginAdapter
  undef_method :current_user
end

class WrongSignatureHostAdapter < RailsNewadmin::HostAuthenticationAdapter
  def current_user = nil
  def active?(user:) = true
  def login_path(controller:) = "/login"
  def logout_path(controller:) = "/logout"
end

class HostIdentityTest < ActiveSupport::TestCase
  setup do
    @original = RailsNewadmin.configuration
    @config = RailsNewadmin::Configuration.new
    @config.authentication = :host
    @config.authentication_adapter = "ExistingLoginAdapter"
    RailsNewadmin.instance_variable_set(:@configuration, @config)
  end

  teardown { RailsNewadmin.instance_variable_set(:@configuration, @original) }

  test "host mode accepts an explicit reloadable adapter class name" do
    assert_same @config, @config.validate!
    assert_same ExistingLoginAdapter, RailsNewadmin::HostAuthentication.adapter_class
  end

  test "incomplete missing wrong-type and wrong-signature adapters fail explicitly" do
    %w[IncompleteHostAdapter WrongSignatureHostAdapter HiddenHostAdapter UndefinedHostAdapter UnknownHostAdapter String].each do |name|
      @config.authentication_adapter = name
      assert_raises(RailsNewadmin::ConfigurationError, name) { RailsNewadmin::HostAuthentication.adapter_class }
    end
  end

  test "configuration rejects invalid modes and malformed adapter configuration" do
    [ nil, ExistingLoginAdapter, "unsafe;code", "" ].each do |adapter|
      @config.authentication_adapter = adapter
      assert_raises(RailsNewadmin::ConfigurationError) { @config.validate! }
    end
    @config.authentication = :builtin
    @config.authentication_adapter = "ExistingLoginAdapter"
    assert_raises(RailsNewadmin::ConfigurationError) { @config.validate! }
    @config.authentication_adapter = nil
    @config.authentication = :unknown
    assert_raises(RailsNewadmin::ConfigurationError) { @config.validate! }
    [ { available_locales: [] }, { session_lifetime: 0 }, { site_title: "" }, { dashboard_provider: "unsafe" } ].each do |values|
      config = RailsNewadmin::Configuration.new
      values.each { |key, value| config.public_send("#{key}=", value) }
      assert_raises(RailsNewadmin::ConfigurationError) { config.validate! }
    end
  end

  test "identity keys preserve type and stable scalar primary key without passwords" do
    organization = Organization.create!(name: "Bridge")
    user = User.create!(email_address: "bridge@example.test", password: "host password", organization: organization)
    identity = RailsNewadmin::ActorIdentity.create!(**RailsNewadmin::ActorIdentity.key_for(user))
    assert_equal "User", identity.actor_type
    assert_equal user.id.to_s, identity.actor_id
    refute identity.administrative?
    refute identity.respond_to?(:password_digest)
    assert_equal identity, RailsNewadmin::ActorIdentity.for_user(user)
    refute RailsNewadmin::ActorIdentity.new(actor_type: "User", actor_id: user.id.to_s).valid?
    assert_nil RailsNewadmin::ActorIdentity.for_user(organization)
    [ nil, Object.new, User.new ].each do |invalid|
      assert_raises(RailsNewadmin::ConfigurationError) { RailsNewadmin::ActorIdentity.key_for(invalid) }
    end
    user.destroy!
    assert_raises(RailsNewadmin::ConfigurationError) { RailsNewadmin::ActorIdentity.key_for(user) }
    composite = Class.new(User) { self.primary_key = [ :id, :email_address ] }
    invalid = composite.new
    invalid.instance_variable_set(:@new_record, false)
    assert_raises(RailsNewadmin::ConfigurationError) { RailsNewadmin::ActorIdentity.key_for(invalid) }
  end

  test "memberships are unique and grant only active permissions" do
    identity = RailsNewadmin::ActorIdentity.create!(actor_type: "Account", actor_id: "uuid-key", active: true, staff: true, locale: "en")
    group = RailsNewadmin::Group.create!(name: "Host group")
    permission = RailsNewadmin::Permission.create!(resource_key: "sample", action: "view")
    group.permissions << permission
    identity.groups << group
    assert identity.has_permission?("sample", "view")
    refute identity.has_permission?("sample", "destroy")
    refute RailsNewadmin::ActorMembership.new(actor_identity: identity, group: group).valid?
    permission.update!(active: false)
    refute identity.has_permission?("sample", "view")
    group.destroy!
    assert_empty identity.actor_memberships.reload
    identity.groups << RailsNewadmin::Group.create!(name: "Second")
    identity.destroy!
    assert_equal 0, RailsNewadmin::ActorMembership.count
  end

  test "host redirects reject external malformed and engine-local paths" do
    controller = Struct.new(:request).new(Struct.new(:script_name).new("/admin"))
    resolver = RailsNewadmin::HostAuthentication.new(controller)
    [ nil, "https://evil.test", "//evil.test", "/\\evil.test", "/host\n", "/admin", "/admin/session/new", "/bad%ZZ", "/outside/../admin", "/outside/./login", "/%2e%2e/admin", "/outside/%2E./admin", "/outside%2f..%2fadmin", "/%252e%252e/admin", "/%5cevil.test" ].each do |path|
      assert_raises(RailsNewadmin::ConfigurationError, path.inspect) { resolver.send(:local_host_path, path) }
    end
    assert_equal "/login?locale=en", resolver.send(:local_host_path, "/login?locale=en")
    controller.request.script_name = "/portal/control"
    assert_raises(RailsNewadmin::ConfigurationError) { resolver.send(:local_host_path, "/portal/control/session/new") }
    assert_equal "/portal/session/new", resolver.send(:local_host_path, "/portal/session/new")
    assert_equal "/portal/control-room/login", resolver.send(:local_host_path, "/portal/control-room/login")
    controller.request.script_name = ""
    assert_equal "/login", resolver.send(:local_host_path, "/login")
  end
end
