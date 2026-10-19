require "test_helper"
require "minitest/mock"

class PasswordRecoveryTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
    ActionMailer::Base.deliveries.clear
    @user = RailsNewadmin::AdminUser.create!(email_address: "recovery@example.test", password: "twelve words password", staff: true)
  end

  test "recovery responses do not disclose whether an account exists" do
    get "/admin/password/new"
    csrf_request :post, "/admin/password", params: { email_address: @user.email_address }
    assert_response :see_other
    notice = flash[:notice]
    assert_equal 1, ActionMailer::Base.deliveries.length
    message = ActionMailer::Base.deliveries.last
    assert_equal [ @user.email_address ], message.to
    assert_includes message.body.to_s, "/admin/password/edit?token="
    get "/admin/password/new"
    csrf_request :post, "/admin/password", params: { email_address: "absent@example.test" }
    assert_equal notice, flash[:notice]
    assert_equal 1, ActionMailer::Base.deliveries.length
  end

  test "reset expires and revokes sessions and previous reset token" do
    session_token = RailsNewadmin::AdminSession.start!(@user)
    token = @user.password_reset_token
    get "/admin/password/edit", params: { token: token }
    assert_response :success
    csrf_request :patch, "/admin/password", params: { token: token, password: "changed secure password", password_confirmation: "changed secure password" }
    assert_response :see_other
    assert @user.reload.authenticate("changed secure password")
    assert_nil RailsNewadmin::AdminSession.resume(session_token)
    get "/admin/password/edit", params: { token: token }
    assert_redirected_to "/admin/password/new"
    token = @user.password_reset_token
    travel 16.minutes do
      get "/admin/password/edit", params: { token: token }
      assert_redirected_to "/admin/password/new"
    end
  end

  test "invalid reset and mismatched passwords cannot change credentials" do
    get "/admin/password/edit", params: { token: "tampered" }
    assert_redirected_to "/admin/password/new"
    get "/admin/password/edit", params: { token: @user.password_reset_token }
    csrf_request :patch, "/admin/password", params: { token: @user.password_reset_token, password: "another password", password_confirmation: "not matching" }
    assert_response :unprocessable_entity
    assert @user.reload.authenticate("twelve words password")
  end

  test "inactive account tokens fail and token query is redacted" do
    token = @user.password_reset_token
    get "/admin/password/edit", params: { token: token }
    refute_includes request.filtered_path, token
    @user.update!(active: false)
    get "/admin/password/edit", params: { token: token }
    assert_redirected_to "/admin/password/new"
  end

  test "recovery attempts are throttled without disclosing accounts" do
    get "/admin/password/new"
    10.times { csrf_request :post, "/admin/password", params: { email_address: "unknown@example.test" } }
    csrf_request :post, "/admin/password", params: { email_address: "unknown@example.test" }
    assert_response :too_many_requests
    assert_empty ActionMailer::Base.deliveries
  end

  test "recovery requires a trusted configured mail host" do
    original = Rails.application.config.action_mailer.default_url_options
    Rails.application.config.action_mailer.default_url_options = {}
    get "/admin/password/new"
    assert_raises(RailsNewadmin::ConfigurationError) do
      csrf_request :post, "/admin/password", params: { email_address: @user.email_address }
    end
  ensure
    Rails.application.config.action_mailer.default_url_options = original
  end

  test "production links use the configured host over https" do
    original = RailsNewadmin.configuration.rate_limit_store
    backend = Object.new
    backend.define_singleton_method(:increment) { |*args, **options| Rails.cache.increment(*args, **options) }
    RailsNewadmin.configuration.rate_limit_store = backend
    get "/admin/password/new"
    Rails.stub(:env, "production".inquiry) do
      csrf_request :post, "/admin/password", params: { email_address: @user.email_address }
    end
    assert_includes ActionMailer::Base.deliveries.last.body.to_s, "https://www.example.com/admin/password/edit"
  ensure
    RailsNewadmin.configuration.rate_limit_store = original
  end
  test "recovery requires a nonblank new password on the server" do
    token = @user.password_reset_token
    get "/admin/password/edit", params: { token: token }
    csrf_request :patch, "/admin/password", params: { token: token, password: "", password_confirmation: "" }
    assert_response :unprocessable_entity
    assert @user.reload.authenticate("twelve words password")
  end
end
