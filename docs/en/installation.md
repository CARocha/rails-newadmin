# Installation

This guide describes development alpha 0.1.0.alpha.1. Use Ruby 3.4+, a full Rails 8.0 or 8.1 application, Active Record, Action Mailer and Propshaft. Examples assume an existing `Article` model. API-only apps require the HTML/session stack and are outside this alpha's tested setup.

Until the RubyGems release, install from GitHub. The `main` branch follows alpha development:

```ruby
gem "rails-newadmin", git: "https://github.com/CARocha/rails-newadmin.git", branch: "main", require: "rails/newadmin"
```

```sh
bundle install
bin/rails generate rails_newadmin:install
bin/rails db:migrate
bin/rails generate rails_newadmin:resource Article
bin/rails rails_newadmin:permissions:sync
bin/rails rails_newadmin:admin:create
bin/rails server
```

The account task prompts in a terminal; there are no default credentials. Running the installer twice preserves the initializer and avoids duplicate migrations/mounts. Choose a different initial mount with `--path /control`; a conflicting path is rejected. Inspect `bin/rails routes`.

A generated resource is closed. Configure its policy and fields using [Resources](resources.md), then visit `/admin`.

For a supplied `.gem`, run `gem install /path/rails-newadmin-0.1.0.alpha.1.gem`, declare that version with `require: "rails/newadmin"` in the Gemfile, then `bundle install --local`. Dependencies must already exist or be downloaded from RubyGems. Consumers need neither npm nor Python.

Install this alpha from GitHub. `gem install rails-newadmin` requires a release published to RubyGems.

## Reverse the installation

From the Rails application, preview and run the reversal:

```sh
bin/rails destroy rails_newadmin:install --pretend
bin/rails destroy rails_newadmin:install
```

The installer removes its generated initializer and mount only while they remain unchanged. You do not need to repeat `--path` to remove a generated alternate mount. Edited or pre-existing configuration and routes are preserved, with a message to review them manually. Older installations whose files cannot be identified as generated are preserved too.

**Migrations, tables, accounts, permissions and data are always retained.** The command neither rolls back the database nor removes your application's models, resources or policies. Do not delete an applied migration as part of this cleanup.

Review `config/routes.rb`: if a customized mount was preserved, remove it manually to disable access to the panel. Before removing the gem from the Gemfile, remove remaining engine references from application configuration too.

Reinstall with `bin/rails generate rails_newadmin:install` (or `--path /control` for another path). Existing migrations are reused and customizations are retained. Repeating installation or reversal does not duplicate migrations.

For an existing application login, follow [Use an existing Rails login](authentication.md#use-an-existing-rails-login) instead of creating a builtin account.
