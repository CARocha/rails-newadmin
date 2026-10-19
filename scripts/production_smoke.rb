# Run inside a disposable host with Article(title, body, status):
# RAILS_ENV=production bin/rails runner /path/to/scripts/production_smoke.rb
require "securerandom"
require "nokogiri"
raise "Production required" unless Rails.env.production?
if ENV["PACKAGED_ROOT"]
  raise "Consumer loaded source checkout" unless RailsNewadmin::Engine.root.realpath.to_s == File.realpath(ENV.fetch("PACKAGED_ROOT"))
end
raise "Node unexpectedly available" if ENV["VERIFY_WITHOUT_NODE"] == "1" && system("command -v node >/dev/null 2>&1")
begin
password = SecureRandom.base64(24)
user = RailsNewadmin::AdminUser.create!(email_address: "smoke-#{SecureRandom.hex(8)}@example.test", password: password, staff: true, superuser: true)
RailsNewadmin::Permission.sync!
session = ActionDispatch::Integration::Session.new(Rails.application)
session.host! "www.example.com"
session.https!
mount = ENV.fetch("ADMIN_MOUNT", "/control")
session.get "#{mount}/session/new"
raise "Login form unavailable" unless session.response.status == 200
token = Nokogiri::HTML(session.response.body).at_css('meta[name="csrf-token"]')["content"]
css = Nokogiri::HTML(session.response.body).at_css('link[rel="stylesheet"]')["href"]
session.post "#{mount}/session", params: { email_address: user.email_address, password: password }, headers: { "X-CSRF-Token" => token }
raise "Login failed" unless session.response.status == 303
session.get "#{mount}/resources/articles/new"
raise "Resource form unavailable" unless session.response.status == 200
token = Nokogiri::HTML(session.response.body).at_css('meta[name="csrf-token"]')["content"]
session.post "#{mount}/resources/articles", params: { record: { title: "Packaged production smoke", body: "Fictional content", status: "draft" } }, headers: { "X-CSRF-Token" => token }
raise "CRUD failed #{session.response.status}" unless session.response.status == 303
session.get "#{mount}/resources/articles"
raise "Created record missing" unless session.response.status == 200 && session.response.body.include?("Packaged production smoke")
session.get css
raise "Compiled stylesheet unavailable" unless session.response.status == 200
puts "Packaged production login, CSRF, CRUD, alternate mount and compiled asset: passed"
ensure
  if defined?(user) && user&.persisted?
    RailsNewadmin::AuditEvent.where(actor_type: user.class.name, actor_id: user.id.to_s).delete_all
    user.destroy!
  end
  Article.where(title: "Packaged production smoke").destroy_all if defined?(Article)
end
