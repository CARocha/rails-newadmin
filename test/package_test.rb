require "rubygems"
gem "minitest", "~> 5.25"
require "minitest/autorun"
require "open3"

class PackageTest < Minitest::Test
  def test_declares_supported_runtime_and_loads_without_an_application
    specification = Gem::Specification.load(File.expand_path("../rails-newadmin.gemspec", __dir__))
    refute_nil specification, "the distributable gemspec must exist"
    assert_equal "rails-newadmin", specification.name
    refute specification.required_ruby_version.satisfied_by?(Gem::Version.new("3.3.9"))
    assert specification.required_ruby_version.satisfied_by?(Gem::Version.new("3.4.0"))
    assert specification.required_ruby_version.satisfied_by?(Gem::Version.new("4.0.0"))
    require "rails/newadmin"
    assert_equal "0.1.0.alpha.1", RailsNewadmin::VERSION
    assert_operator RailsNewadmin::Engine, :<, Rails::Engine
    refute specification.runtime_dependencies.any? { |dependency| dependency.name == "devise" }
    output, status = Open3.capture2e(Gem.ruby, "-Ilib", "-e", 'require "rails/newadmin"; abort if Rails.application')
    assert status.success?, output
  end
end
