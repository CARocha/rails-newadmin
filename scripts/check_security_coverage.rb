require "json"
result = JSON.parse(File.read("coverage/.resultset.json"))
suffixes = %w[
  lib/rails_newadmin/access_management.rb
  lib/rails_newadmin/access.rb
  lib/rails_newadmin/policy.rb
  app/models/rails_newadmin/admin_user.rb
  app/models/rails_newadmin/admin_session.rb
  app/controllers/rails_newadmin/application_controller.rb
  app/controllers/rails_newadmin/sessions_controller.rb
  app/controllers/rails_newadmin/passwords_controller.rb
]
coverage = result.values.fetch(0).fetch("coverage")
values = suffixes.flat_map do |suffix|
  entry = coverage.find { |path, _data| path.end_with?("/#{suffix}") }
  abort "Missing security coverage: #{suffix}" unless entry
  entry.last.fetch("branches").values.flat_map(&:values)
end
abort "Missing security branches" if values.empty?
percent = 100.0 * values.count(&:positive?) / values.size
puts "Authentication and authorization branch coverage: #{percent.round(2)}%"
abort "Security branch coverage must reach 95%" if percent < 95
