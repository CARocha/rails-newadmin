require "test_helper"

class ResourceTest < ActiveSupport::TestCase
  test "resource declarations are independent explicit and immutable" do
    resource = Class.new(RailsNewadmin::Resource) do
      model "Article"
      key "articles"
      columns :title, :status
      fields :title, :status
      permit :title
      search :title
      filters :status
      policy "ArticleAdminPolicy"
    end
    assert_equal "Article", resource.model_name
    assert_equal [ :title ], resource.permitted_fields
    assert resource.column_names.frozen?
    assert_empty Class.new(RailsNewadmin::Resource).permitted_fields
    registry = RailsNewadmin::Registry.new([ resource ])
    assert_same resource, registry.fetch("articles")
    assert_raises(KeyError) { registry.fetch("Object") }
    assert_raises(RailsNewadmin::ConfigurationError) { RailsNewadmin::Registry.new([ resource, resource ]) }
  end

  test "invalid configuration and unsafe field declarations fail early" do
    assert_raises(RailsNewadmin::ConfigurationError) { RailsNewadmin::Configuration.new.tap { |c| c.default_mode = :invalid }.validate! }
    assert_raises(RailsNewadmin::ConfigurationError) { Class.new(RailsNewadmin::Resource).key("../users") }
    assert_raises(RailsNewadmin::ConfigurationError) { Class.new(RailsNewadmin::Resource).permit("title; DROP TABLE users") }
    assert_raises(RailsNewadmin::ConfigurationError) { RailsNewadmin::Configuration.new.tap { |c| c.authentication = :host }.validate! }
  end

  test "configuration validation preserves host locale configuration" do
    original = I18n.available_locales
    config = RailsNewadmin::Configuration.new
    assert_equal [ :es, :en ], config.available_locales
    config.validate!
    assert_equal original, I18n.available_locales
  end
end
