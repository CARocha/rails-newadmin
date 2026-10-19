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
end
