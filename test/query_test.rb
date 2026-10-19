require "test_helper"

class QueryTest < ActiveSupport::TestCase
  test "bounded search treats SQL and wildcard input as data" do
    organization = Organization.create!(name: "Query")
    user = RailsNewadmin::AdminUser.create!(email_address: "query@example.test", password: "twelve words password", staff: true, superuser: true)
    AdminProfile.create!(admin_user: user, organization: organization)
    Article.create!(title: "100% result", status: "draft", organization: organization)
    Article.create!(title: "Other result", status: "published", organization: organization)
    access = RailsNewadmin::Access.new(user, ArticleResource)
    query = RailsNewadmin::Query.new(access, { q: "%", per_page: 10_000, page: -1 })
    assert_equal 100, query.per_page
    assert_equal 1, query.page
    assert_equal ["100% result"], query.records.pluck(:title)
    filtered = RailsNewadmin::Query.new(access, { filters: { "status" => "published" }, sort: "title", direction: "asc" })
    assert_equal ["Other result"], filtered.records.pluck(:title)
    injected = RailsNewadmin::Query.new(access, { q: "' OR 1=1 --" })
    assert_empty injected.records
  end
end
