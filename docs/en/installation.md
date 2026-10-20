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
