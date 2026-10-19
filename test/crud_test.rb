require "test_helper"

class CrudTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.clear
    @organization = Organization.create!(name: "Editorial")
    @other_organization = Organization.create!(name: "Other")
    @user = RailsNewadmin::AdminUser.create!(email_address: "editor@example.test", password: "twelve words password", staff: true, superuser: true)
    AdminProfile.create!(admin_user: @user, organization: @organization)
    @category = Category.create!(name: "News", organization: @organization)
    @foreign_category = Category.create!(name: "Private category", organization: @other_organization)
    @article = Article.create!(title: "Welcome", status: "draft", organization: @organization, category: @category)
    @foreign_article = Article.create!(title: "Confidential", status: "draft", organization: @other_organization, category: @foreign_category)
    login_admin(@user)
  end

  test "list and detail respect policy scope even for a superuser" do
    get "/admin/resources/articles"
    assert_response :success
    assert_includes response.body, "Welcome"
    refute_includes response.body, "Confidential"
    get "/admin/resources/articles/#{@foreign_article.id}"
    assert_response :not_found
    get "/admin/resources/Object"
    assert_response :not_found
  end

  test "create and edit use explicit fields and server-assigned organization" do
    get "/admin/resources/articles/new"
    csrf_request :post, "/admin/resources/articles", params: { record: { title: "Created", status: "published", organization_id: @other_organization.id, secret_token: "injected" } }
    assert_response :see_other
    created = Article.find_by!(title: "Created")
    assert_equal @organization.id, created.organization_id
    assert_nil created.secret_token
    get "/admin/resources/articles/#{created.id}/edit"
    csrf_request :patch, "/admin/resources/articles/#{created.id}", params: { record: { title: "Updated" } }
    assert_response :see_other
    assert_equal "Updated", created.reload.title
  end

  test "invalid fields render accessible errors and preserve values" do
    get "/admin/resources/articles/new"
    csrf_request :post, "/admin/resources/articles", params: { record: { title: "", status: "draft" } }
    assert_response :unprocessable_entity
    assert_select "[role=alert]"
    assert_select "input[name='record[title]'][aria-invalid=true]"
  end

  test "viewer cannot write by sending a request directly" do
    @user.update!(superuser: false)
    group = RailsNewadmin::Group.create!(name: "Readers")
    group.admin_users << @user
    group.permissions << RailsNewadmin::Permission.create!(resource_key: "articles", action: "view")
    get "/admin/resources/articles"
    assert_response :success
    csrf_request :patch, "/admin/resources/articles/#{@article.id}", params: { record: { title: "Forbidden" } }
    assert_response :forbidden
    assert_equal "Welcome", @article.reload.title
  end

  test "relationship choices and assignments cannot cross organizations" do
    get "/admin/resources/articles/options/category", params: { q: "" }
    assert_response :success
    assert_includes response.body, "News"
    refute_includes response.body, "Private category"
    get "/admin/resources/articles/#{@article.id}/edit"
    csrf_request :patch, "/admin/resources/articles/#{@article.id}", params: { record: { category_id: @foreign_category.id } }
    assert_response :unprocessable_entity
    assert_equal @category.id, @article.reload.category_id
  end

  test "delete requires confirmation and mutation is protected against CSRF" do
    get "/admin/resources/articles/#{@article.id}/delete"
    assert_response :success
    assert Article.exists?(@article.id)
    delete "/admin/resources/articles/#{@article.id}"
    assert_response :unprocessable_entity
    assert Article.exists?(@article.id)
    get "/admin/resources/articles/#{@article.id}/delete"
    csrf_request :delete, "/admin/resources/articles/#{@article.id}"
    assert_response :see_other
    refute Article.exists?(@article.id)
  end

  test "filter and sort input is bounded and allowlisted" do
    get "/admin/resources/articles", params: { sort: "title; DROP TABLE articles", per_page: "100000", filters: { status: "draft", secret_token: "hidden" } }
    assert_response :success
    assert Article.exists?(@article.id)
    assert_includes response.body, "Welcome"
  end

  test "missing permission is denied before a business record query" do
    @user.update!(superuser: false)
    queries = []
    subscriber = ->(*args) { sql = args.last[:sql]; queries << sql if sql.include?('FROM "articles"') }
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      get "/admin/resources/articles/#{@article.id}"
    end
    assert_response :forbidden
    assert_empty queries
  end

  test "an authorized current relationship remains selected beyond the first options page" do
    25.times { |index| Category.create!(name: "Category #{index}", organization: @organization) }
    get "/admin/resources/articles/#{@article.id}/edit"
    assert_response :success
    assert_select "select[name='record[category_id]'] option[selected][value='#{@category.id}']"
  end
end
