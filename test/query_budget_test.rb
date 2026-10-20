require "test_helper"
require "minitest/mock"
require_relative "support/query_recorder"

class QueryBudgetTest < ActionDispatch::IntegrationTest
  class AssociationPolicy < ArticleAdminPolicy
    def allowed?(actor:, action:, record: nil)
      !record || record.category.organization_id == record.organization_id
    end
  end

  def setup
    @previous_policy = ArticleResource.policy_name
    @previous_preloads = ArticleResource.preload_names
    ArticleResource.policy "QueryBudgetTest::AssociationPolicy"
    ArticleResource.includes :category
    organization = Organization.create!(name: "Query budget")
    @user = RailsNewadmin::AdminUser.create!(email_address: "budget@example.test", password: "twelve words password", staff: true)
    AdminProfile.create!(admin_user: @user, organization: organization)
    @group = RailsNewadmin::Group.create!(name: "Budget editors")
    @group.admin_users << @user
    %w[view update].each { |action| @group.permissions << RailsNewadmin::Permission.find_or_create_by!(resource_key: "articles", action: action) }
    50.times do |index|
      category = Category.create!(name: "Category #{index}", organization: organization)
      Article.create!(title: "Article #{index}", status: "draft", organization: organization, category: category)
    end
    login_admin(@user)
    get "/admin/resources/articles"
  end

  def teardown
    ArticleResource.policy_name = @previous_policy
    ArticleResource.preload_names = @previous_preloads
    super
  end

  def measure_page(size)
    recorder = QueryRecorder.new.capture { get "/admin/resources/articles", params: { per_page: size } }
    assert_response :success
    assert_select "tbody tr", count: size
    recorder
  end

  test "25 to 50 rows keep full request SQL bounded with association based authorization" do
    ActiveRecord::Base.uncached do
      small, large = measure_page(25), measure_page(50)
      assert_operator large.queries - small.queries, :<=, 2
      assert_operator large.executed, :<=, 20
      assert_equal 0, large.cached
    end
  end

  test "query cache cannot hide a missing policy association preload" do
    ArticleResource.includes
    ActiveRecord::Base.uncached do
      small, large = measure_page(25), measure_page(50)
      assert_operator large.queries - small.queries, :>=, 25, "negative control must detect the removed preload"
    end
  end

  test "logical counts still expose repeated queries when SQL is cached" do
    ArticleResource.includes
    Article.update_all(category_id: Category.first.id)
    access = RailsNewadmin::Access.new(@user, ArticleResource, permissions: [ [ "articles", "view" ], [ "articles", "update" ] ])
    measure = lambda do |size|
      QueryRecorder.new.capture do
        RailsNewadmin::Query.new(access, { per_page: size }).records.each { |record| access.allowed?(:update, record) }
      end
    end
    ActiveRecord::Base.cache do
      small, large = measure.call(25), measure.call(50)
      assert_operator large.cached, :>, 0
      assert_operator large.queries - small.queries, :>=, 25
    end
  end

  test "query event includes actual materialization count duration and safe metadata" do
    events = []
    sql = nil
    ActiveSupport::Notifications.subscribed(->(event) { events << event }, "query.rails_newadmin") do
      sql = measure_page(25)
    end
    assert_equal 1, events.size
    event = events.first
    assert_equal %i[operation page per_page request_id resource_key success], event.payload.keys.sort
    assert_equal "articles", event.payload[:resource_key]
    assert_equal "list", event.payload[:operation]
    assert_equal 25, event.payload[:per_page]
    assert event.payload[:success]
    relevant = sql.events.select { |item| item.payload[:sql].match?(/FROM "(?:articles|categories)"/) }
    assert_operator relevant.size, :>=, 3
    assert relevant.all? { |item| item.time >= event.time && item.end <= event.end }, "collection SQL must run inside the event"
  end

  test "options event identifies the authorized target and keeps search terms private" do
    @group.permissions << RailsNewadmin::Permission.find_or_create_by!(resource_key: "categories", action: "view")
    events = []
    instantiated = 0
    instantiations = ->(event) { instantiated += event.payload[:record_count] if event.payload[:class_name] == "Category" }
    ActiveSupport::Notifications.subscribed(instantiations, "instantiation.active_record") do
      ActiveSupport::Notifications.subscribed(->(event) { events << event }, "query.rails_newadmin") do
        get "/admin/resources/articles/options/category", params: { q: "Category", per_page: 100_000 }
      end
    end
    assert_response :success
    assert_operator JSON.parse(response.body).size, :<=, 20
    assert_operator instantiated, :<=, 20
    assert_equal 1, events.size
    assert_equal "categories", events.first.payload[:resource_key]
    assert_equal "options", events.first.payload[:operation]
    assert_equal 20, events.first.payload[:per_page]
    refute_includes events.first.payload.inspect, "Category"
  end

  test "ties use a stable primary key and bounded pages" do
    access = RailsNewadmin::Access.new(@user, ArticleResource)
    first = RailsNewadmin::Query.new(access, { sort: "status", direction: "asc", per_page: 25 }).records.map(&:id)
    second = RailsNewadmin::Query.new(access, { sort: "status", direction: "asc", per_page: 25, page: 2 }).records.map(&:id)
    assert_equal Article.order(id: :desc).limit(50).pluck(:id), first + second
    assert_empty first & second
  end

  test "denied collections emit no query event" do
    @group.permissions.clear
    events = []
    ActiveSupport::Notifications.subscribed(->(event) { events << event }, "query.rails_newadmin") { get "/admin/resources/articles" }
    assert_response :forbidden
    assert_empty events
  end

  test "query failure preserves the error without publishing exception details" do
    events = []
    original = RailsNewadmin::Query.method(:new)
    fault = lambda do |*arguments|
      query = original.call(*arguments)
      def query.count = raise("sensitive database diagnostic")
      query
    end
    ActiveSupport::Notifications.subscribed(->(event) { events << event }, "query.rails_newadmin") do
      RailsNewadmin::Query.stub(:new, fault) do
        error = assert_raises(RuntimeError) { get "/admin/resources/articles", params: { q: "private filter value" } }
        assert_equal "sensitive database diagnostic", error.message
      end
    end
    assert_equal 1, events.size
    refute events.first.payload[:success]
    refute_match(/sensitive|private|exception|SELECT/, events.first.payload.inspect)
  end
end
