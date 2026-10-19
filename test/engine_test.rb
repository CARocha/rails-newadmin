require "test_helper"

class EngineTest < ActionDispatch::IntegrationTest
  test "engine is isolated and default routes cannot expose business records" do
    assert RailsNewadmin::Engine.isolated?
    get "/admin"
    assert_redirected_to "/admin/session/new"
    get "/host"
    assert_response :success
    assert_equal "Host application", response.body
  end

  test "admin login loads only locally packaged assets" do
    get "/admin/session/new"
    assert_select "link[rel=stylesheet][href^='/assets/rails_newadmin/']"
    assert_select "script[src^='/assets/rails_newadmin/']", minimum: 1
    assert_no_match %r{https?://(?:cdn|fonts)}, response.body
  end
end
