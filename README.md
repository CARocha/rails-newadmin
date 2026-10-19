# rails-newadmin

Independent Rails administration with the NewAdmin visual identity. Ruby **3.4+**; Rails **8.0–8.1**. Local development alpha `0.1.0.alpha.1`, not published to RubyGems yet.

[Español](README.es.md) · [English manual](docs/en/index.md) · [Verification and limits](VERIFICATION.md)

A mountable engine with independent accounts (Rails `has_secure_password`, no Devise), group permissions, explicit policy scopes, CRUD, transactional audit, Spanish/English UI, light/dark/automatic theme and optional local ECharts dashboards. The palettes and system typography come from django-newadmin; this is a new administration engine rather than a skin for another gem.

## Try it in an existing full Rails application

Add the local checkout to your application's Gemfile until publication:

```ruby
gem "rails-newadmin", path: "/absolute/path/to/rails-newadmin", require: "rails/newadmin"
```

```sh
bundle install
bin/rails generate rails_newadmin:install
bin/rails db:migrate
bin/rails generate rails_newadmin:resource Article
bin/rails rails_newadmin:permissions:sync
bin/rails rails_newadmin:admin:create
```

`Article` must already exist. The generated policy denies access and write fields are empty until you explicitly configure both. Start Rails and visit `/admin`. Follow the [resource guide](docs/en/resources.md) before enabling data access. No models are discovered or exposed automatically, and a superuser never bypasses policy scope.

Consumers use the packaged, precompiled assets with Propshaft: no Node, Sass, Python or Sphinx at runtime. Development of the gem uses Node to rebuild assets; documentation uses Sphinx.

## Development

```sh
bundle install
bundle exec rails db:migrate RAILS_ENV=test
bundle exec rake test
COVERAGE=1 bundle exec rake test
bundle exec rubocop
npm ci
npm run build
```

See [contributing](docs/en/contributing.md), [security](SECURITY.md), [changelog](CHANGELOG.md) and the [approved plan](tasks/plan.en.md). Production requires a shared atomic rate-limit store and configured email delivery. Host-login integration, advanced exports, bulk operations and uploads are future work. This alpha is not a 1.0 certification.

BSD-3-Clause. Vendored components retain their own licenses; see [NOTICE](NOTICE).
