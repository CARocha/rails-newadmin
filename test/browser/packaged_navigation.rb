require "socket"
require "net/http"

module PackagedNavigation
  def self.run(root:, host:, ruby:, execute:, production:)
    node = `command -v node`.strip
    raise "Node required for the browser driver" if node.empty?
    FileUtils.cp_r(File.join(root, "test/browser/host_app/."), host)
    vendor = File.join(host, "vendor/javascript")
    FileUtils.mkdir_p(vendor)
    FileUtils.cp(File.join(root, "node_modules/@hotwired/turbo/dist/turbo.es2017-esm.js"), File.join(vendor, "host_turbo.js"))
    FileUtils.cp(File.join(root, "node_modules/@hotwired/stimulus/dist/stimulus.js"), File.join(vendor, "host_stimulus.js"))
    execute.call([ node, File.join(root, "test/browser/build_host.mjs"), host ], root)
    routes = File.join(host, "config/routes.rb")
    contents = File.read(routes).sub(/^  root .+$/, '  root "navigation_fixture#show"' + "\n  get \"second\", to: \"navigation_fixture#show\", as: :host_second")
    File.write(routes, contents)
    # The fixture is served only on loopback HTTP, with disposable credentials.
    File.write(File.join(host, "config/initializers/navigation_fixture.rb"), <<~RUBY)
      Rails.application.config.force_ssl = false
      Rails.application.config.assume_ssl = false
      RailsNewadmin.configuration.dashboard_provider = "NavigationDashboard"
    RUBY
    view = File.join(host, "app/views/rails_newadmin/dashboard/index.html.erb")
    FileUtils.mkdir_p(File.dirname(view))
    File.write(view, File.read(File.join(root, "app/views/rails_newadmin/dashboard/index.html.erb")) + '<%= link_to "Return to host", main_app.root_path, id: "return-to-host" %>')
    credentials = File.join(host, "tmp/navigation-credentials.json")
    FileUtils.mkdir_p(File.dirname(credentials))
    execute.call([ ruby, "bin/rails", "runner", File.join(root, "test/browser/seed.rb") ], host,
      production.merge("NAVIGATION_CREDENTIALS" => credentials, "NAVIGATION_JS" => "importmap"))
    %w[importmap esbuild].each do |variant|
      [ "", "/portal" ].each do |prefix|
        environment = production.merge("NAVIGATION_JS" => variant, "NAVIGATION_PREFIX" => prefix.empty? ? "/" : prefix,
          "RAILS_RELATIVE_URL_ROOT" => (prefix.empty? ? nil : prefix), "RAILS_SERVE_STATIC_FILES" => "1", "WEB_CONCURRENCY" => "0")
        FileUtils.rm_rf(File.join(host, "public/assets"))
        execute.call([ ruby, "bin/rails", "assets:precompile" ], host, environment)
        port = TCPServer.open("127.0.0.1", 0) { |socket| socket.addr[1] }
        log_path = File.join(root, "pkg/navigation-#{variant}-#{prefix.empty? ? 'root' : 'prefix'}.log")
        File.open(log_path, "w") do |log|
          pid = Process.spawn(environment, ruby, "bin/rails", "server", "-b", "127.0.0.1", "-p", port.to_s,
            "-P", File.join(host, "tmp/pids/server.pid"), chdir: host, out: log, err: [ :child, :out ])
          begin
            deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 20
            loop do
              begin
                response = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}#{prefix}/session/new"))
                break if response.code == "200"
              rescue Errno::ECONNREFUSED, EOFError
                # Wait for this newly spawned fixture server to boot.
              end
              raise "Navigation fixture failed to boot; inspect #{log_path}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
              sleep 0.1
            end
            execute.call([ node, File.join(root, "test/browser/navigation.mjs"), "http://127.0.0.1:#{port}", prefix, credentials, variant ], root)
          ensure
            begin
              Process.kill("TERM", pid)
            rescue Errno::ESRCH
              # The failed server has already exited.
            end
            Process.wait(pid)
          end
        end
      end
    end
    puts "Packaged importmap/esbuild host and admin browser navigation at root and deployment prefix: passed"
  end
end
