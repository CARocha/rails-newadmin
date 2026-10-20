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
  test "concurrent anonymous requests keep their locale isolated" do
    # Rails 8.0 lazy route loading is not the concurrency behavior under test.
    Rails.application.reload_routes_unless_loaded
    initial = I18n.locale
    results = %w[es en].map do |locale|
      Thread.new do
        session = ActionDispatch::Integration::Session.new(Rails.application)
        session.get "/admin/session/new", params: { locale: locale }
        [ locale, session.response.status, Nokogiri::HTML(session.response.body).at_css("html")["lang"] ]
      end
    end.map(&:value)
    assert_equal [ [ "es", 200, "es" ], [ "en", 200, "en" ] ], results
    assert_equal initial, I18n.locale
  end
end
