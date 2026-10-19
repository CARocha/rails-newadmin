require "test_helper"

class RateLimitTest < ActionDispatch::IntegrationTest
  test "native limiter blocks repeated login attempts" do
    Rails.cache.clear
    get "/admin/session/new"
    10.times do
      csrf_request :post, "/admin/session", params: { email_address: "unknown@example.test", password: "incorrect password" }
      assert_response :unprocessable_entity
    end
    csrf_request :post, "/admin/session", params: { email_address: "unknown@example.test", password: "incorrect password" }
    assert_response :too_many_requests
  end

  test "production rejects process-local and null limit stores" do
    [ ActiveSupport::Cache::MemoryStore.new, ActiveSupport::Cache::NullStore.new ].each do |store|
      assert_raises(RailsNewadmin::ConfigurationError) { RailsNewadmin::RateLimitStore.validate_shared!(store) }
    end
  end
end
