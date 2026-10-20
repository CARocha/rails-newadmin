# rails-newadmin

Independent Rails administration with the NewAdmin visual identity. **Ruby 3.4+ · Rails 8.0–8.1**. Development alpha `0.1.0.alpha.1`, not yet published to RubyGems.

[Español](README.es.md) · [User manual](docs/en/index.md)

Manage Active Record resources with independent accounts or an existing host login, group permissions, scoped policies, CRUD and audit history. Includes Spanish/English interfaces, light/dark/automatic appearance and optional dashboards with local charts. Authentication uses Rails primitives without Devise.

## Install

Add the GitHub repository to your application's Gemfile:

```ruby
gem "rails-newadmin", git: "https://github.com/CARocha/rails-newadmin.git", branch: "main", require: "rails/newadmin"
```

The `main` branch follows alpha development. Use a full Rails application with Active Record, Action Mailer and Propshaft.

```sh
bundle install
bin/rails generate rails_newadmin:install
bin/rails db:migrate
bin/rails generate rails_newadmin:resource Article
bin/rails rails_newadmin:permissions:sync
bin/rails rails_newadmin:admin:create
```

`Article` must already exist. The account task prompts for credentials; there are no default accounts. The generated resource policy starts closed and permits no writes. Configure its [policy and fields](docs/en/resources.md), start Rails, then visit `/admin`. Models are never automatically exposed, and superusers remain subject to policy scopes.

Consumers use packaged assets and do not need Node, Sass, Python or Sphinx.

## Configure

The installer creates `config/initializers/rails_newadmin.rb`:

```ruby
RailsNewadmin.configure do |config|
  config.site_title = "My administration"
  config.default_locale = :en
  config.default_mode = :auto
end
```

- [Installation and alternate mount paths](docs/en/installation.md)
- [Resources, policies and relations](docs/en/resources.md)
- [Accounts, existing host login and password recovery](docs/en/authentication.md)
- [Groups, permissions and audit](docs/en/permissions.md)
- [Appearance and locale](docs/en/appearance.md)
- [Dashboards and charts](docs/en/dashboards.md)
- [Host navigation, importmap/esbuild and deployment prefixes](docs/en/navigation.md)
- [Keyboard, tables, validation and accessibility customization](docs/en/accessibility.md)
- [Production configuration](docs/en/production.md)
- [Troubleshooting and upgrades](docs/en/troubleshooting.md)

Production requires HTTPS, shared atomic rate-limit storage and configured mail delivery. Choose independent admin accounts or an explicit [host-login adapter](docs/en/authentication.md#use-an-existing-rails-login) with separate group memberships and no second password. Exports, bulk actions and uploads are unavailable.

[Security](SECURITY.md) · [Changelog](CHANGELOG.md) · [BSD-3-Clause license](LICENSE). Bundled components retain their own licenses; see [NOTICE](NOTICE).
