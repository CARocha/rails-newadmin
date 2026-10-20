# Isolated builtin-auth fixture: no real accounts or developer databases.
require "bundler/setup"
require "tmpdir"
require "open3"
require "socket"
require "net/http"
require_relative "packaged_navigation"
# Keep disposable-fixture failures readable through public check annotations.
if ENV["GITHUB_ACTIONS"] == "true"
  at_exit do
    error = $!
    if error && !(error.is_a?(SystemExit) && error.success?)
      message = error.full_message(highlight: false).lines.first(45).join
      message = message.gsub("%", "%25").gsub("\r", "%0D").gsub("\n", "%0A")
      warn "::error title=Accessibility diagnostic::#{message}"
    end
  end
end
root = File.expand_path("../..", __dir__)
ruby = RbConfig.ruby
Dir.mktmpdir("newadmin-accessibility-") do |directory|
  environment = { "RAILS_ENV" => "development", "DATABASE_URL" => "sqlite3:#{directory}/fixture.sqlite3",
    "NEWADMIN_DEMO_DASHBOARD" => "1", "NEWADMIN_DEMO_HOST_AUTH" => nil, "WEB_CONCURRENCY" => "0",
    "A11Y_CREDENTIALS" => File.join(directory, "credentials.json") }
  run = lambda do |*command|
    output, status = Open3.capture2e(environment, *command, chdir: root)
    raise "Accessibility command failed: #{command.first(3).join(' ')}\n#{output.lines.last(35).join}" unless status.success?
    puts output
  end
  run.call(ruby, "-S", "bundle", "exec", "rails", "db:migrate")
  run.call(ruby, "-S", "bundle", "exec", "rails", "runner", File.join(root, "test/browser/accessibility_seed.rb"))
  port = TCPServer.open("127.0.0.1", 0) { |socket| socket.addr[1] }
  File.open(File.join(directory, "server.log"), "w") do |log|
    pid = Process.spawn(environment, ruby, "-S", "bundle", "exec", "rails", "server", "-b", "127.0.0.1", "-p", port.to_s,
      "-P", File.join(directory, "server.pid"), chdir: root, out: log, err: [ :child, :out ])
    begin
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
      loop do
        begin
          break if Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/admin/session/new")).code == "200"
        rescue Errno::ECONNREFUSED, EOFError
          # This fixture alone owns the process and database.
        end
        raise "Fixture boot failed: #{File.read(log.path)}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
        sleep 0.1
      end
      run.call(PackagedNavigation.node_executable, "test/browser/accessibility.mjs", "http://127.0.0.1:#{port}", environment.fetch("A11Y_CREDENTIALS"))
    ensure
      Process.kill("TERM", pid) rescue Errno::ESRCH
      Process.wait(pid)
    end
  end
end
