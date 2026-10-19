require "test_helper"
require "yaml"

class I18nTest < ActiveSupport::TestCase
  test "both admin locales expose identical keys and interpolation variables" do
    flatten = lambda do |hash, prefix = ""|
      hash.flat_map do |key, value|
        path = "#{prefix}.#{key}"
        value.is_a?(Hash) ? flatten.call(value, path).to_a : [ [ path, value.to_s.scan(/%\{([^}]+)\}/).flatten.sort ] ]
      end.to_h
    end
    locales = %w[es en].map do |locale|
      data = YAML.safe_load(File.read(RailsNewadmin::Engine.root.join("config/locales/rails_newadmin.#{locale}.yml")))
      flatten.call(data.fetch(locale).fetch("rails_newadmin"))
    end
    assert_equal locales.first, locales.last
  end
end
