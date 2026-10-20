require "test_helper"

class AccessibilityTest < ActionDispatch::IntegrationTest
  def setup
    @user = RailsNewadmin::AdminUser.create!(email_address: "a11y@example.test", password: "twelve words password", staff: true, superuser: true)
    login_admin(@user)
  end

  test "page titles identify the current screen" do
    get "/admin/admin_users", params: { locale: :en }
    assert_select "title", "#{I18n.t("rails_newadmin.access.users", locale: :en)} · NewAdmin"
    get "/admin/groups", params: { locale: :en }
    assert_select "title", /Groups.*NewAdmin/
  end

  test "denied pages explain the failure without leaking resource data" do
    @user.update!(superuser: false)
    get "/admin/resources/articles", params: { locale: :en }
    assert_response :forbidden
    assert_select "html[lang=en] main h1", "Access denied"
    assert_select "title", /Access denied/
    assert_select "aside", count: 0
    get "/admin/resources/articles/options/category", headers: { "Accept" => "application/json" }
    assert_response :forbidden
    assert_empty response.body
  end

  test "account errors name invalid fields and link a focusable summary" do
    get "/admin/admin_users/new"
    csrf_request :post, "/admin/admin_users", params: { admin_user: { email_address: "invalid", password: "short", password_confirmation: "different" } }
    assert_response :unprocessable_entity
    assert_select "#newadmin-errors[tabindex='-1'][data-controller='newadmin-errors']"
    assert_select "a[href='#admin_user_email_address']"
    assert_select "#admin_user_email_address[aria-invalid='true'][aria-describedby='admin_user_email_address_error']"
    assert_select "#admin_user_email_address_error", /.+/
  end

  test "group errors are associated with the name input" do
    get "/admin/groups/new"
    csrf_request :post, "/admin/groups", params: { group: { name: "" } }
    assert_response :unprocessable_entity
    assert_select "#group_name[aria-invalid='true'][aria-describedby='group_name_error']"
    assert_select "#group_name_error", /.+/
  end

  test "password reset errors use the unscoped password input ids" do
    token = @user.password_reset_token
    get "/admin/password/edit", params: { token: token }
    csrf_request :patch, "/admin/password", params: { token: token, password: "short", password_confirmation: "different" }
    assert_response :unprocessable_entity
    assert_select "#password[aria-invalid='true'][aria-describedby='password_error']"
    assert_select "#password_error", /.+/
    assert_select "#newadmin-errors a[href='#password']"
  end

  test "all management tables are named keyboard scroll regions" do
    %w[admin_users groups].each do |path|
      get "/admin/#{path}"
      assert_select ".newadmin-table-scroll[tabindex='0'][role='region'][aria-label] table"
    end
  end
end
