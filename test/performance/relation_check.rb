# Explicit, disposable-database scale check. Not part of normal unit tests.
ENV["RAILS_ENV"] = "test"
require_relative "../dummy/config/environment"
require "securerandom"
require "nokogiri"
raise "Set NEWADMIN_DISPOSABLE_BENCH=1 on a disposable DB" unless ENV["NEWADMIN_DISPOSABLE_BENCH"] == "1"
begin
  organization = Organization.create!(name: "Scale #{SecureRandom.hex(8)}")
  user = RailsNewadmin::AdminUser.create!(email_address: "scale-#{SecureRandom.hex(8)}@example.test", password: SecureRandom.base64(24), staff: true, superuser: true)
  AdminProfile.create!(admin_user: user, organization: organization)
  100.times do |batch|
    Category.insert_all!(1_000.times.map { |index| { name: "Option #{batch * 1_000 + index}", organization_id: organization.id } })
  end
  session = ActionDispatch::Integration::Session.new(Rails.application)
  session.get "/admin/session/new"
  token = Nokogiri::HTML(session.response.body).at_css('meta[name="csrf-token"]')["content"]
  session.post "/admin/session", params: { email_address: user.email_address, password: user.password }, headers: { "X-CSRF-Token" => token }
  session.get "/admin/resources/articles/options/category"
  data = JSON.parse(session.response.body)
  raise "Unbounded or failed options" unless session.response.status == 200 && data.length == 20
  raise "Wrong dataset" unless Category.where(organization: organization).count == 100_000
  session.get "/admin/resources/articles/options/category", params: { q: "Option 99999" }
  raise "Search failed" unless JSON.parse(session.response.body).map { |item| item["label"] } == [ "Option 99999" ]
  puts "100,000 related records: 20-result bound and search passed"
ensure
  Category.where(organization_id: organization.id).delete_all if defined?(organization) && organization&.persisted?
  AdminProfile.where(admin_user_id: user.id).delete_all if defined?(user) && user&.persisted?
  user&.destroy! if defined?(user)
  organization&.destroy! if defined?(organization)
end
