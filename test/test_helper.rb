ENV["RAILS_ENV"] = "test"
require "bundler/setup"
require_relative "support/coverage_setup" if ENV["COVERAGE"] == "1"
require "rails/newadmin"
require_relative "dummy/config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    self.use_transactional_tests = true
  end
end

class ActionDispatch::IntegrationTest
  def csrf_token
    token = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')&.[]("content")
    @csrf_token = token if token
    @csrf_token
  end

  def csrf_request(method, path, **options)
    options[:headers] = (options[:headers] || {}).merge("X-CSRF-Token" => csrf_token)
    public_send(method, path, **options)
  end

  def login_admin(user, password: "twelve words password")
    get "/admin/session/new"
    csrf_request :post, "/admin/session", params: { email_address: user.email_address, password: password }
    follow_redirect!
  end
end
