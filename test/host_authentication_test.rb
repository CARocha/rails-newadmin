require "test_helper"

class NonBooleanActiveHostAdapter < ExistingLoginAdapter
  def active?(user:) = "yes"
end

class InvalidUserHostAdapter < ExistingLoginAdapter
  def current_user(controller:) = Object.new
end

class HostAuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @original = RailsNewadmin.configuration
    RailsNewadmin.instance_variable_set(:@configuration, RailsNewadmin::Configuration.new)
    RailsNewadmin.configuration.authentication = :host
    RailsNewadmin.configuration.authentication_adapter = "ExistingLoginAdapter"
    @organization = Organization.create!(name: "Host tenant")
    @user = User.create!(email_address: "host@example.test", password: "existing host password", organization: @organization)
    @identity = RailsNewadmin::ActorIdentity.create!(**RailsNewadmin::ActorIdentity.key_for(@user), active: true, staff: true)
    RailsNewadmin::Permission.sync!
    @group = RailsNewadmin::Group.create!(name: "Host editors")
    @group.permissions = RailsNewadmin::Permission.where(resource_key: "articles")
    @identity.groups << @group
    @article = Article.create!(title: "My tenant", organization: @organization)
    @other = Article.create!(title: "Other tenant", organization: Organization.create!(name: "Other"))
  end

  teardown { RailsNewadmin.instance_variable_set(:@configuration, @original) }

  test "guests go to the existing login without creating accounts or engine sessions" do
    assert_no_difference [ "RailsNewadmin::AdminUser.count", "RailsNewadmin::AdminSession.count", "RailsNewadmin::ActorIdentity.count" ] do
      get "/admin"
      assert_redirected_to "/host_session/new"
    end
  end

  test "existing host login authorizes only scoped records and audits the original identity" do
    sign_in
    assert_response :success
    assert_select 'form[action="/host_session"] input[name="_method"][value="delete"]'
    assert_select 'a[href="/admin/admin_users"]', count: 0
    get "/admin/resources/articles"
    assert_response :success
    assert_includes response.body, "My tenant"
    assert_not_includes response.body, "Other tenant"
    get "/admin/resources/articles/#{@other.id}"
    assert_response :not_found
    get "/admin/resources/articles/#{@article.id}/edit"
    csrf_request :patch, "/admin/resources/articles/#{@article.id}", params: { record: { title: "Host edited" } }
    assert_response :see_other
    assert_equal "Host edited", @article.reload.title
    event = RailsNewadmin::AuditEvent.order(:id).last
    assert_equal [ "User", @user.id.to_s ], [ event.actor_type, event.actor_id ]
    assert_equal 0, RailsNewadmin::AdminSession.count
  end

  test "ordinary host users are forbidden even if builtin credentials or matching IDs exist" do
    owner = RailsNewadmin::AdminUser.create!(id: @user.id, email_address: @user.email_address,
      password: "twelve words password", staff: true, superuser: true)
    RailsNewadmin.configuration.authentication = :builtin
    login_admin(owner)
    RailsNewadmin.configuration.authentication = :host
    @identity.destroy!
    sign_in
    assert_response :forbidden
    get "/admin/resources/articles"
    assert_response :forbidden
    assert_equal 0, RailsNewadmin::ActorIdentity.count
  end

  test "inactive host accounts and inactive or nonstaff identities are forbidden on the next request" do
    sign_in
    @user.update!(active: false)
    get "/admin"
    assert_response :forbidden
    @user.update!(active: true)
    @identity.update!(active: false)
    get "/admin"
    assert_response :forbidden
    @identity.update!(active: true, staff: false)
    get "/admin"
    assert_response :forbidden
  end

  test "group revocation applies on the next request and owner still obeys policy scope" do
    sign_in
    @identity.groups.clear
    get "/admin/resources/articles"
    assert_response :forbidden
    @identity.update!(superuser: true)
    get "/admin/resources/articles/#{@other.id}"
    assert_response :not_found
    get "/admin/resources/articles"
    assert_response :success
  end

  test "logout uses the host endpoint and session revocation is observed" do
    sign_in
    assert_difference "Session.count", -1 do
      csrf_request :delete, "/host_session"
      assert_redirected_to "/host_session/new"
    end
    get "/admin"
    assert_redirected_to "/host_session/new"
  end

  test "server side host session revocation is observed without a builtin fallback" do
    sign_in
    @user.sessions.destroy_all
    get "/admin"
    assert_redirected_to "/host_session/new"
  end

  test "builtin login recovery and account endpoints are disabled in host mode" do
    sign_in
    paths = { get: %w[/admin/session/new /admin/password/new /admin/password/edit?token=invalid /admin/admin_users /admin/admin_users/new /admin/admin_users/1/edit],
      post: %w[/admin/session /admin/password /admin/admin_users], patch: %w[/admin/password /admin/admin_users/1], delete: %w[/admin/session] }
    paths.each do |method, urls|
      urls.each do |url|
        csrf_request method, url, params: { email_address: "unused@example.test" }
        assert_response :not_found, "#{method} #{url}"
      end
    end
  end

  test "host mode retains CSRF protection for resources and host logout" do
    sign_in
    patch "/admin/resources/articles/#{@article.id}", params: { record: { title: "Attack" } }
    assert_response :unprocessable_entity
    delete "/host_session"
    assert_response :unprocessable_entity
    assert_equal "My tenant", @article.reload.title
    assert_equal 1, Session.count
  end

  test "privileged host actors manage groups but cannot mutate builtin owners" do
    @identity.update!(superuser: true)
    sign_in
    get "/admin/groups/new"
    assert_response :success
    csrf_request :post, "/admin/groups", params: { group: { name: "Managed by host", permission_ids: [] } }
    assert_response :see_other
    assert_equal "User", RailsNewadmin::AuditEvent.order(:id).last.actor_type
    assert_raises(RailsNewadmin::AccessDenied) do
      actor = RailsNewadmin::HostActor.new(@user, @identity)
      RailsNewadmin::AccessManagement.new(actor).update_user!(RailsNewadmin::AdminUser.new, {})
    end
  end

  test "adapter errors and nonboolean active results cannot fall back to builtin" do
    sign_in
    RailsNewadmin.configuration.authentication_adapter = "NonBooleanActiveHostAdapter"
    get "/admin"
    assert_response :forbidden
    RailsNewadmin.configuration.authentication_adapter = "InvalidUserHostAdapter"
    assert_raises(RailsNewadmin::ConfigurationError) { get "/admin" }
    assert_equal 0, RailsNewadmin::AdminSession.count
  end

  test "host mode does not offer builtin password account creation tasks" do
    require "rake"
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    load RailsNewadmin::Engine.root.join("lib/tasks/rails_newadmin.rake") unless Rake::Task.task_defined?("rails_newadmin:admin:create")
    Rake::Task["rails_newadmin:admin:create"].reenable
    _stdout, stderr = capture_io do
      assert_raises(SystemExit) { Rake::Task["rails_newadmin:admin:create"].invoke }
    end
    assert_includes stderr, "Host authentication uses ActorIdentity"
  ensure
    Rake::Task["rails_newadmin:admin:create"].reenable
  end

  private

  def sign_in
    get "/host_session/new"
    csrf_request :post, "/host_session", params: { email_address: @user.email_address, password: "existing host password" }
    assert_response :see_other
    follow_redirect!
  end
end
