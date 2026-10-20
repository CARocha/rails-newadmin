# frozen_string_literal: true

require_relative "lib/rails_newadmin/version"

Gem::Specification.new do |spec|
  spec.name = "rails-newadmin"
  spec.version = RailsNewadmin::VERSION
  spec.authors = [ "CARocha" ]
  spec.summary = "An independent Rails admin with the NewAdmin design and explicit permissions."
  spec.description = "A mountable Rails administration engine with local assets, scoped resource policies and Spanish/English interfaces."
  spec.homepage = "https://github.com/CARocha/rails-newadmin"
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "#{spec.homepage}/tree/main/docs"
  spec.license = "BSD-3-Clause"
  spec.required_ruby_version = ">= 3.4"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.files = Dir.chdir(__dir__) do
    Dir["{app,config,db,lib}/**/*", "vendor/licenses/**/*", "LICENSE", "README.md", "README.es.md", "CHANGELOG.md", "NOTICE"].select { |path| File.file?(path) }
  end
  spec.require_paths = [ "lib" ]
  %w[railties actionpack actionview activerecord activejob actionmailer].each do |name|
    spec.add_dependency name, ">= 8.0", "< 8.2"
  end
  spec.add_dependency "bcrypt", "~> 3.1"
  # Active Support 8.0 passes quirks_mode, which JSON 3 removed.
  spec.add_dependency "json", ">= 2.18", "< 3"
end
