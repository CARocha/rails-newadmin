# Run separately: RAILS_ENV=development bundle exec ruby test/development/reload_check.rb
require_relative "../dummy/config/environment"
RailsNewadmin.configuration.authentication = :host
RailsNewadmin.configuration.authentication_adapter = "ExistingLoginAdapter"
GC.disable
begin
previous_adapter = ExistingLoginAdapter
3.times do
  Rails.application.reloader.reload!
  adapter = RailsNewadmin::HostAuthentication.adapter_class
  raise "Adapter class survived reload" if adapter.equal?(previous_adapter)
  previous_adapter = adapter
  expected = [ ArticleResource, CategoryResource ].sort_by(&:name)
  actual = RailsNewadmin.registry.to_a.sort_by(&:name)
  raise "Registry holds stale or duplicate resource classes" unless actual == expected
end
puts "Three development reloads retain current resources and host adapter classes"
ensure
  GC.enable
end
