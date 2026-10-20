# Production

Use HTTPS, a secure `SECRET_KEY_BASE`, backups and trusted proxies. Rate limiting needs shared atomic increment operations. MemoryStore, FileStore and NullStore are rejected in production; failed increments close access. Custom backends must meet the semantic contract, not merely expose a method name.

```ruby
# Gemfile: Redis is one supported example chosen by the host.
gem "redis", "~> 5.0"
# config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL") }
config.action_mailer.default_url_options = { host: "admin.example.com", protocol: "https" }
config.action_mailer.default_options = { from: "no-reply@example.com" }
# config/initializers/rails_newadmin.rb
RailsNewadmin.configure { |config| config.rate_limit_store = Rails.cache }
```

Configure actual mail transport and a durable Active Job queue; fictional test deliveries do not certify your SMTP. Redact upstream tokens/query logs. Run `RAILS_ENV=production bin/rails assets:precompile` and serve `public/assets` through your application infrastructure. Bundles are already compiled; Node is unnecessary.

Host/engine layout navigation is verified with importmap and esbuild, including alternate mounts and a deployment prefix. Follow [Navigation and assets](navigation.md) to configure links and keep a single Turbo runtime.

Do not widen the Rails range to 8.2/9 without the matrix. Ruby 3.4 is the floor; satisfying the gemspec alone does not certify future Rubies. This alpha was exercised on Ruby 3.4.8.
