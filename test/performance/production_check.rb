# Standalone production fixture; invoked by scripts/performance_check.rb only.
require "bundler/setup"
require "json"
require "nokogiri"
require "etc"
require "fileutils"
require "zlib"
require "digest"
require "tmpdir"
require "open3"
raise "Production required" unless ENV["RAILS_ENV"] == "production"
expected_database = ENV.fetch("NEWADMIN_DISPOSABLE_BENCH")
raise "Disposable database marker required" unless /\Anewadmin_perf_[a-f0-9]{16}\z/.match?(expected_database)
require_relative "../dummy/config/application"
Dummy::Application.configure do
  config.eager_load = true
  config.rake_eager_load = true
  config.enable_reloading = false
  config.assets.output_path = Pathname(ENV.fetch("NEWADMIN_BENCH_ASSETS"))
end
RailsNewadmin.configure do |config|
  config.rate_limit_store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("NEWADMIN_REDIS_URL"), namespace: expected_database)
end
require_relative "../dummy/config/environment"
require_relative "../support/query_recorder"
raise "Wrong database" unless ActiveRecord::Base.connection.select_value("SELECT current_database()") == expected_database
raise "Fixture database was not empty" if ActiveRecord::Base.connection.data_sources.any?
paths = [ RailsNewadmin::Engine.root.join("db/migrate"), Rails.root.join("db/migrate") ]
ActiveRecord::MigrationContext.new(paths).migrate
Rails.application.load_tasks
Rake::Task["assets:precompile"].invoke
raise "Production cache/eager-load flags missing" unless Rails.application.config.eager_load && !Rails.application.config.enable_reloading
class PerformanceArticlePolicy < ArticleAdminPolicy
  def allowed?(actor:, action:, record: nil)
    !record || record.category.organization_id == record.organization_id
  end
end
ArticleResource.policy "PerformanceArticlePolicy"
organization = Organization.create!(name: "Synthetic performance tenant")
other = Organization.create!(name: "Synthetic foreign tenant")
user = RailsNewadmin::AdminUser.create!(email_address: "performance@example.test", password: SecureRandom.base64(24), staff: true)
AdminProfile.create!(admin_user: user, organization: organization)
group = RailsNewadmin::Group.create!(name: "Synthetic editors")
group.admin_users << user
[ [ "articles", "view" ], [ "articles", "update" ], [ "categories", "view" ] ].each do |key, action|
  group.permissions << RailsNewadmin::Permission.find_or_create_by!(resource_key: key, action: action)
end
Category.insert_all!((0...1000).map { |index| { name: "Category #{index}", organization_id: organization.id } })
category_ids = Category.where(organization: organization).order(:id).pluck(:id)
10.times do |batch|
  Article.insert_all!((0...1000).map do |index|
    number = batch * 1000 + index
    { title: "Article #{number}", body: "Synthetic body for a bounded list measurement.", status: number.even? ? "draft" : "published",
      category_id: category_ids[number % 1000], organization_id: organization.id, created_at: Time.current, updated_at: Time.current }
  end)
end
foreign = Category.create!(name: "Foreign confidential option", organization: other)
Article.create!(title: "Foreign confidential article", status: "draft", organization: other, category: foreign)
session = ActionDispatch::Integration::Session.new(Rails.application)
session.https!
session.get "/admin/session/new"
token = Nokogiri::HTML(session.response.body).at_css('meta[name="csrf-token"]')["content"]
session.post "/admin/session", params: { email_address: user.email_address, password: user.password }, headers: { "X-CSRF-Token" => token }
raise "Fixture login failed" unless session.response.status == 303

def list_request(session, params)
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  session.get "/admin/resources/articles", params: params
  elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000
  raise "List failed" unless session.response.status == 200
  raise "Foreign tenant leaked" if session.response.body.include?("Foreign confidential")
  elapsed
end

def profile(session, params)
  cold = list_request(session, params)
  counts = QueryRecorder.new.capture { list_request(session, params) }
  5.times { list_request(session, params) }
  repetitions = 3.times.map do
    samples = 100.times.map { list_request(session, params) }.sort
    { samples: samples.size, p50_ms: samples[(samples.size * 0.50).ceil - 1].round(3), p95_ms: samples[(samples.size * 0.95).ceil - 1].round(3) }
  end
  { first_request_ms: cold.round(3), warmup_requests: 5, percentile_method: "nearest rank", sql_logical: counts.queries, sql_executed: counts.executed, sql_cached: counts.cached, query_cache_enabled_states: counts.cache_states.uniq,
    html_bytes: session.response.body.bytesize, repetitions: repetitions }
end

hardware = if RUBY_PLATFORM.include?("darwin")
  { cpu: Open3.capture2("/usr/sbin/sysctl", "-n", "machdep.cpu.brand_string").first.strip,
    memory_bytes: Open3.capture2("/usr/sbin/sysctl", "-n", "hw.memsize").first.to_i }
else
  { cpu: File.read("/proc/cpuinfo")[/^model name\s*:\s*(.+)$/, 1],
    memory_bytes: File.read("/proc/meminfo")[/^MemTotal:\s*(\d+)/, 1].to_i * 1024 }
end
report = { environment: { ruby: RUBY_DESCRIPTION, rails: Rails.version, postgres: ActiveRecord::Base.connection.select_value("SHOW server_version"),
  platform: RUBY_PLATFORM, cpus: Etc.nprocessors, hardware: hardware, yjit: defined?(RubyVM::YJIT) ? RubyVM::YJIT.enabled? : false, environment: Rails.env, eager_load: Rails.application.config.eager_load,
  reloading: Rails.application.config.enable_reloading, requests_in_flight: 1, processes: 1, transport: "in-process Rack integration, PostgreSQL server local/network per configured admin connection",
  cache: "request-local ActiveRecord query cache; warm application/templates; no cross-request result cache",
  logging: "dummy fixture logger to null", dataset: { articles: 10_000, categories: 1_000, tenants: 2, foreign_business_records: 2 },
  database_transport: ActiveRecord::Base.connection.raw_connection.host.start_with?("/") ? "Unix socket" : "TCP",
  statement_timeout: ActiveRecord::Base.connection.select_value("SHOW statement_timeout"),
  source_sha: `git rev-parse HEAD`.strip,
  runtime_source_sha256: Digest::SHA256.file(RailsNewadmin::Engine.root.join("app/controllers/rails_newadmin/resources_controller.rb")).hexdigest }, profiles: {} }
ArticleResource.includes
report[:profiles][:without_preload_25] = profile(session, { per_page: 25 })
report[:profiles][:without_preload_50] = profile(session, { per_page: 50 })
ArticleResource.includes :category
report[:profiles][:preload_25] = profile(session, { per_page: 25 })
report[:profiles][:preload_50] = profile(session, { per_page: 50 })
report[:profiles][:preload_deep_page] = profile(session, { page: 200, per_page: 25 })
report[:profiles][:preload_filtered_search] = profile(session, { q: "Article 999", filters: { status: "draft" }, sort: "title", direction: "asc" })
raise "N+1 positive control not sensitive" unless report[:profiles][:without_preload_50][:sql_logical] - report[:profiles][:without_preload_25][:sql_logical] >= 25
raise "Query budget regressed" unless report[:profiles][:preload_50][:sql_logical] - report[:profiles][:preload_25][:sql_logical] <= 2
raise "Absolute query budget regressed" unless report[:profiles][:preload_50][:sql_logical] <= 20
[ {}, { per_page: 100_000 }, { page: 2, sort: "status", direction: "asc" } ].each do |params|
  list_request(session, params)
  count = Nokogiri::HTML(session.response.body).css("tbody tr").size
  raise "Page bound failed" unless count == (params[:per_page] ? 100 : 25)
end
99.times do |batch|
  Category.insert_all!((0...1000).map { |index| { name: "Category #{1000 + batch * 1000 + index}", organization_id: organization.id } })
end
raise "Incorrect options dataset" unless Category.where(organization: organization).count == 100_000
instantiated = 0
subscriber = ->(event) { instantiated += event.payload[:record_count] if event.payload[:class_name] == "Category" }
counts = nil
ActiveSupport::Notifications.subscribed(subscriber, "instantiation.active_record") do
  counts = QueryRecorder.new.capture { session.get "/admin/resources/articles/options/category", params: { per_page: 100_000 } }
end
raise "Unbounded choice materialization" if instantiated > 20
choices = JSON.parse(session.response.body)
raise "Unbounded options" unless session.response.status == 200 && choices.size == 20
raise "Foreign options leaked" if choices.any? { |row| row["label"].include?("Foreign") }
session.get "/admin/resources/articles/options/category", params: { q: "Category 99999" }
raise "Options search failed" unless JSON.parse(session.response.body).map { |row| row["label"] } == [ "Category 99999" ]
session.get "/admin/resources/articles/options/category", params: { q: "Foreign confidential" }
raise "Foreign search leaked" unless session.response.status == 200 && JSON.parse(session.response.body).empty?
report[:latency_reference] = { target_p95_ms: 300, gate: "recorded only; no noisy wall-clock CI threshold",
  measured_target_met: report[:profiles].reject { |key, _| key.to_s.start_with?("without_") }.values.all? { |value| value[:repetitions].all? { |row| row[:p95_ms] < 300 } } }
report[:options] = { tenant_categories: 100_000, results: choices.size, instantiated: instantiated, sql_logical: counts.queries, sql_executed: counts.executed }
queries = {
  list_first_page: Article.where(organization_id: organization.id).order(id: :desc).limit(25),
  options_search: RailsNewadmin::Query.new(RailsNewadmin::Access.new(user, CategoryResource), { q: "Category 99999", per_page: 20 }).records
}
report[:explain] = queries.transform_values do |query|
  JSON.parse(ActiveRecord::Base.connection.select_value("EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) #{query.to_sql}"))
end
FileUtils.mkdir_p(File.join(RailsNewadmin::Engine.root, "pkg"))
output = ENV.fetch("NEWADMIN_BENCH_OUTPUT", File.join(RailsNewadmin::Engine.root, "pkg/performance.json"))
File.write(output, JSON.pretty_generate(report))
puts "Production query budgets and 100,000-option fixture passed; report saved locally"
