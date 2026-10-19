require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
    @user = RailsNewadmin::AdminUser.create!(email_address: "admin@example.test", password: "twelve words password", staff: true, superuser: true)
    get "/admin/session/new"
  end

  test "login normalizes email, rotates and revokes a protected session" do
    get "/admin"
    assert_redirected_to "/admin/session/new"
    get "/admin/session/new"
    assert_response :success
    assert_select "input[type=password][autocomplete=current-password]"
    csrf_request :post, "/admin/session", params: { email_address: " ADMIN@example.test ", password: "twelve words password" }
    assert_redirected_to "/admin/"
    assert_equal 1, @user.sessions.count
    get "/admin/"
    assert_response :success
    csrf_request :delete, "/admin/session"
    assert_redirected_to "/admin/session/new"
    assert_empty @user.sessions
    get "/admin/"
    assert_redirected_to "/admin/session/new"
  end

  test "inactive and non-staff identities cannot enter" do
    @user.update!(staff: false)
    csrf_request :post, "/admin/session", params: { email_address: @user.email_address, password: "twelve words password" }
    assert_empty @user.sessions
    assert_response :unprocessable_entity
    @user.update!(active: false, staff: true)
    csrf_request :post, "/admin/session", params: { email_address: @user.email_address, password: "twelve words password" }
    assert_empty @user.sessions
  end

  test "session stores only a token digest and expires on server" do
    token = RailsNewadmin::AdminSession.start!(@user)
    session = @user.sessions.last
    refute_equal token, session.token_digest
    assert_equal 64, session.token_digest.length
    assert_equal session, RailsNewadmin::AdminSession.resume(token)
    session.update!(last_seen_at: 31.minutes.ago)
    assert_nil RailsNewadmin::AdminSession.resume(token)
  end

  test "session is rejected when account deactivated or password changed" do
    token = RailsNewadmin::AdminSession.start!(@user)
    @user.update!(password: "another long password")
    assert_nil RailsNewadmin::AdminSession.resume(token)
    token = RailsNewadmin::AdminSession.start!(@user)
    @user.update!(active: false)
    assert_nil RailsNewadmin::AdminSession.resume(token)
  end

  test "email uniqueness and password length are validated" do
    duplicate = RailsNewadmin::AdminUser.new(email_address: " ADMIN@example.test ", password: "short")
    refute duplicate.valid?
    assert duplicate.errors[:email_address].any?
    assert duplicate.errors[:password].any?
  end

  test "locale is request-local and return destination cannot leave admin" do
    get "/admin/session/new", params: { locale: "en" }
    assert_select "html[lang=en]"
    get "/admin/session/new", params: { locale: "invalid" }
    assert_select "html[lang=es]"
    csrf_request :post, "/admin/session", params: { email_address: @user.email_address, password: "twelve words password", return_to: "https://example.test/steal" }
    assert_redirected_to "/admin/"
  end

  test "signing in again replaces the old session and account locale persists across navigation" do
    @user.update!(locale: "en")
    login_admin(@user)
    assert_select "html[lang=en]"
    old_session = @user.sessions.sole.id
    get "/admin/session/new"
    csrf_request :post, "/admin/session", params: { email_address: @user.email_address, password: "twelve words password" }
    assert_response :see_other
    assert_equal 1, @user.sessions.count
    refute_equal old_session, @user.sessions.sole.id
  end

  test "invalid missing expired and idle tokens remain unusable" do
    assert_nil RailsNewadmin::AdminSession.resume(nil)
    assert_nil RailsNewadmin::AdminSession.resume("x")
    assert_nil RailsNewadmin::AdminSession.resume("x" * 50)
    token = RailsNewadmin::AdminSession.start!(@user)
    record = @user.sessions.sole
    record.update!(last_seen_at: 2.minutes.ago)
    assert RailsNewadmin::AdminSession.resume(token)
    assert_operator record.reload.last_seen_at, :>, 1.minute.ago
    record.update!(expires_at: 1.second.ago)
    assert_nil RailsNewadmin::AdminSession.resume(token)
    @user.update!(active: false)
    assert_raises(ArgumentError) { RailsNewadmin::AdminSession.start!(@user) }
  end
end
