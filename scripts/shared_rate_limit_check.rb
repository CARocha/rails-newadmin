require "securerandom"
require "open3"
require "active_support"
require "active_support/cache"
require_relative "../lib/rails_newadmin/rate_limit_store"
url = ENV.fetch("NEWADMIN_REDIS_URL")
key = "newadmin-shared-check:#{SecureRandom.hex(12)}"
code = <<~'CODE'
  require "active_support"
  require "active_support/cache"
  store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("NEWADMIN_REDIS_URL"))
  puts store.increment(ENV.fetch("CHECK_KEY"), 1, expires_in: 30)
CODE
values = 2.times.map do
  out, error, status = Open3.capture3({ "CHECK_KEY" => key }, RbConfig.ruby, "-rbundler/setup", "-e", code)
  raise error unless status.success?
  Integer(out.strip)
end
raise "Store is not shared" unless values == [ 1, 2 ]
ActiveSupport::Cache::RedisCacheStore.new(url: url).delete(key)
puts "Independent Ruby processes share atomic rate-limit increments"
