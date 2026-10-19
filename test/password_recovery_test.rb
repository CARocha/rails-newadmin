require "test_helper"

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
    assert_equal [@user.email_address], message.to
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
end
