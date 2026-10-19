require "test_helper"
require "rubygems/package"

class PackagingTest < ActiveSupport::TestCase
  test "package allowlist includes runtime assets and excludes local environments" do
    specification = Gem::Specification.load(RailsNewadmin::Engine.root.join("rails-newadmin.gemspec").to_s)
    assert_includes specification.files, "app/assets/builds/rails_newadmin/application.css"
    assert_includes specification.files, "app/assets/builds/rails_newadmin/charts.js"
    assert_includes specification.files, "vendor/licenses/echarts.txt"
    assert specification.files.any? { |path| path.start_with?("db/migrate/") }
    refute specification.files.any? { |path| path.match?(%r{(?:node_modules|vendor/bundle|test/dummy|\.env|\.sqlite3)}) }
    assert_operator specification.files.size, :<, 180
  end
end
