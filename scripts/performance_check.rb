# Creates and drops only its own randomly named database; never benchmarks an existing app DB.
require "bundler/setup"
require "pg"
require "uri"
require "securerandom"
require "tmpdir"
require "open3"
require "json"
if ENV["GITHUB_ACTIONS"] == "true"
  at_exit do
    error = $!
    if error && !(error.is_a?(SystemExit) && error.success?)
      message = error.full_message(highlight: false).lines.first(45).join.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A")
      warn "::error title=Performance diagnostic::#{message}"
    end
  end
end
raise "NEWADMIN_REDIS_URL required for production fixture" unless ENV["NEWADMIN_REDIS_URL"]
root = File.expand_path("..", __dir__)
admin_url = ENV.fetch("NEWADMIN_PG_ADMIN_URL", "postgresql:///postgres")
connection = PG.connect(admin_url)
database = "newadmin_perf_#{SecureRandom.hex(8)}"
quoted = connection.quote_ident(database)
begin
  connection.exec("CREATE DATABASE #{quoted}")
  target = URI(admin_url)
  target.path = "/#{database}"
  Dir.mktmpdir("newadmin-performance-") do |directory|
    environment = { "RAILS_ENV" => "production", "DATABASE_URL" => target.to_s,
      "SECRET_KEY_BASE" => SecureRandom.hex(64), "NEWADMIN_DISPOSABLE_BENCH" => database,
      "NEWADMIN_BENCH_ASSETS" => File.join(directory, "assets") }
    stdout, stderr, status = Open3.capture3(environment, RbConfig.ruby, File.join(root, "test/performance/production_check.rb"), chdir: root)
    puts stdout
    warn stderr unless stderr.empty?
    raise "Performance fixture failed (disposable database removed)\n#{stderr.lines.last(20).join}#{stdout.lines.last(15).join}" unless status.success?
  end
ensure
  connection.exec("DROP DATABASE IF EXISTS #{quoted} WITH (FORCE)")
  connection.close
end
