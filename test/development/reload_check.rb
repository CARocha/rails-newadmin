# Run separately: RAILS_ENV=development bundle exec ruby test/development/reload_check.rb
require_relative "../dummy/config/environment"
GC.disable
begin
3.times do
  Rails.application.reloader.reload!
  expected = [ ArticleResource, CategoryResource ].sort_by(&:name)
  actual = RailsNewadmin.registry.to_a.sort_by(&:name)
  raise "Registry holds stale or duplicate resource classes" unless actual == expected
end
puts "Three development reloads retain only current resource classes"
ensure
  GC.enable
end
