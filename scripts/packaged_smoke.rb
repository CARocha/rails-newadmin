# Build, unpack and consume the distribution, not the source checkout.
require "bundler/setup"
require "rubygems/package"
require "tmpdir"
require "fileutils"
require "securerandom"
require "open3"
root = File.expand_path("..", __dir__)
FileUtils.mkdir_p(File.join(root, "pkg"))
specification = Gem::Specification.load(File.join(root, "rails-newadmin.gemspec"))
archive = File.join(root, "pkg", "#{specification.full_name}.gem")
Dir.chdir(root) { Gem::Package.build(specification, false, false, archive) }
ruby = RbConfig.ruby
bundle = Gem.bin_path("bundler", "bundle")
source_gemfile = Bundler.default_gemfile.to_s
bundle_path = Bundler.settings[:path] && File.expand_path(Bundler.settings[:path], Bundler.root)
log_path = File.join(root, "pkg/production-smoke.log")
File.open(log_path, "w") do |log|
  execute = lambda do |arguments, directory, environment = {}|
    stdout, stderr, status = Open3.capture3(environment, *arguments, chdir: directory)
    log.write(stdout)
    log.write(stderr)
    unless status.success?
      log.flush
      details = (stdout + stderr).lines.last(35).join
      raise "Smoke command failed; inspect #{log_path}\n#{details}"
    end
  end
  Dir.mktmpdir("rails-newadmin-package-") do |directory|
    package_root = File.join(directory, "packed")
    package = Gem::Package.new(archive)
    package.extract_files(package_root)
    File.write(File.join(package_root, "rails-newadmin.gemspec"), package.spec.to_ruby)
    flags = %w[--skip-bundle --skip-git --skip-solid --skip-javascript --skip-hotwire --skip-action-mailbox --skip-action-text --skip-active-storage --skip-action-cable --skip-bootsnap --skip-dev-gems --skip-thruster --skip-rubocop --skip-brakeman --skip-bundler-audit --skip-ci --skip-kamal --skip-docker --skip-test]
    execute.call([ ruby, bundle, "exec", "rails", "new", "host", *flags ], directory, { "BUNDLE_GEMFILE" => source_gemfile })
    host = File.join(directory, "host")
    File.write(File.join(host, "Gemfile"), <<~GEMFILE)
      source "https://rubygems.org"
      gem "rails", "#{Gem.loaded_specs.fetch('railties').version}"
      gem "rails-newadmin", path: "../packed", require: "rails/newadmin"
      gem "propshaft", "~> 1.3"
      gem "sqlite3", "~> 2.1"
      gem "puma", "~> 7.0"
      gem "redis", "~> 5.0"
      gem "importmap-rails", "2.2.2"
    GEMFILE
    File.write(File.join(host, "config/database.yml"), "default: &default\n  adapter: sqlite3\n  database: storage/package.sqlite3\nproduction:\n  <<: *default\ndevelopment:\n  <<: *default\n")
    File.write(File.join(host, "config/initializers/package_smoke.rb"), <<~CONFIG)
      if Rails.env.production?
        RailsNewadmin.configuration.rate_limit_store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("NEWADMIN_REDIS_URL"), namespace: "newadmin-package-smoke")
        Rails.application.config.active_job.queue_adapter = :inline
        Rails.application.config.action_mailer.delivery_method = :test
      end
    CONFIG
    Bundler.with_unbundled_env do
      environment = { "BUNDLE_GEMFILE" => File.join(host, "Gemfile"), "BUNDLE_PATH" => bundle_path, "DATABASE_URL" => nil, "RAILS_ENV" => "development" }
      execute.call([ ruby, bundle, "install", "--local" ], host, environment)
      [ [ "generate", "rails_newadmin:install", "--path", "/control" ],
        [ "generate", "rails_newadmin:install", "--path", "/control" ],
        [ "generate", "model", "Article", "title:string", "body:text", "status:string" ],
        [ "db:migrate" ],
        [ "generate", "rails_newadmin:resource", "Article", "--single-site", "--permit", "title", "body", "status" ] ].each do |arguments|
        execute.call([ ruby, bundle, "exec", "ruby", "bin/rails", *arguments ], host, environment)
      end
      # Verify the real destroy command after migrations and application data exist.
      seed = 'Article.create!(title: "Installer retained data", status: "draft"); RailsNewadmin::AdminUser.create!(email_address: "retained@example.test", password: SecureRandom.base64(24), staff: true)'
      execute.call([ ruby, bundle, "exec", "ruby", "bin/rails", "runner", seed ], host, environment)
      migration_files = Dir[File.join(host, "db/migrate/*.rb")].to_h { |path| [ path, File.binread(path) ] }
      2.times { execute.call([ ruby, bundle, "exec", "ruby", "bin/rails", "destroy", "rails_newadmin:install" ], host, environment) }
      raise "Destroy retained an unchanged initializer" if File.exist?(File.join(host, "config/initializers/rails_newadmin.rb"))
      raise "Destroy retained an unchanged mount" if File.read(File.join(host, "config/routes.rb")).include?("mount RailsNewadmin::Engine")
      raise "Destroy changed migration history" unless migration_files == Dir[File.join(host, "db/migrate/*.rb")].to_h { |path| [ path, File.binread(path) ] }
      raise "Destroy removed a business resource" unless File.file?(File.join(host, "app/admin/resources/article_resource.rb"))
      execute.call([ ruby, bundle, "exec", "ruby", "bin/rails", "generate", "rails_newadmin:install", "--path", "/control" ], host, environment)
      retained = 'abort "Installer changed persisted data" unless Article.exists?(title: "Installer retained data") && RailsNewadmin::AdminUser.exists?(email_address: "retained@example.test")'
      execute.call([ ruby, bundle, "exec", "ruby", "bin/rails", "runner", retained ], host, environment)
      raise "Reinstall changed migration history" unless migration_files == Dir[File.join(host, "db/migrate/*.rb")].to_h { |path| [ path, File.binread(path) ] }
      # Add the application's native Rails login before enabling the host adapter.
      execute.call([ ruby, bundle, "exec", "ruby", "bin/rails", "generate", "authentication" ], host, environment)
      execute.call([ ruby, bundle, "install", "--local" ], host, environment)
      routes = File.join(host, "config/routes.rb")
      File.write(routes, File.read(routes).sub("Rails.application.routes.draw do", 'Rails.application.routes.draw do' + "\n  root to: ->(_env) { [200, {\"content-type\" => \"text/plain\"}, [\"Host home\"]] }"))
      FileUtils.cp(File.join(root, "test/host_app/newadmin_host_adapter.rb"), File.join(host, "app/models/newadmin_host_adapter.rb"))
      production = environment.merge("RAILS_ENV" => "production", "RAILS_LOG_LEVEL" => "warn",
        "SECRET_KEY_BASE" => SecureRandom.hex(64), "PACKAGED_ROOT" => package_root, "VERIFY_WITHOUT_NODE" => "1",
        "PATH" => "#{File.dirname(ruby)}:/usr/bin:/bin")
      [ [ "db:migrate" ], [ "assets:precompile" ], [ "runner", File.join(root, "scripts/production_smoke.rb") ] ].each do |arguments|
        execute.call([ ruby, "bin/rails", *arguments ], host, production)
      end
      FileUtils.rm(File.join(host, "config/initializers/rails_newadmin.rb"))
      execute.call([ ruby, bundle, "exec", "ruby", "bin/rails", "generate", "rails_newadmin:install", "--path", "/control", "--authentication=host", "--authentication-adapter=NewadminHostAdapter" ], host, environment)
      execute.call([ ruby, "bin/rails", "runner", File.join(root, "scripts/host_production_smoke.rb") ], host, production)
      if ENV["NEWADMIN_BROWSER_CHECK"] == "1"
        require_relative "../test/browser/packaged_navigation"
        PackagedNavigation.run(root: root, host: host, ruby: ruby, execute: execute, production: production)
      end
    end
  end
end
puts "Real package, install/destroy/reinstall with retained data and builtin and native host authentication in production without Node: passed"
