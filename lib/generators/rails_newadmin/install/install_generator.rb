require "rails/generators"
require "rails/generators/active_record"

module RailsNewadmin
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root Engine.root.join("db/migrate")
      class_option :authentication, type: :string, default: "builtin"
      class_option :path, type: :string, default: "/admin"

      def self.next_migration_number(directory)
        ActiveRecord::Generators::Base.next_migration_number(directory)
      end

      def validate_destination
        raise Thor::Error, "Only builtin authentication is available in this alpha" unless options[:authentication] == "builtin"
        raise Thor::Error, "path must be an absolute path with simple segments" unless %r{\A/(?:[a-z][a-z0-9_-]*)(?:/[a-z][a-z0-9_-]*)*\z}.match?(options[:path])
        routes = File.join(destination_root, "config/routes.rb")
        raise Thor::Error, "Run this inside a full Rails application" unless File.file?(routes)
        @routes = File.read(routes)
        own_mount = @routes.include?("mount RailsNewadmin::Engine")
        path_pattern = /["']#{Regexp.escape(options[:path])}(?:\/|["'])/
        raise Thor::Error, "Mount path already appears in routes; choose --path" if !own_mount && @routes.match?(path_pattern)
      end

      def install_configuration
        path = "config/initializers/rails_newadmin.rb"
        if File.exist?(File.join(destination_root, path))
          say_status :preserve, path
        else
          create_file path, <<~RUBY
            RailsNewadmin.configure do |config|
              config.site_title = "NewAdmin"
              config.default_locale = :es
              config.default_mode = :auto
              # Production requires a shared atomic cache for rate limiting.
              # config.rate_limit_store = Rails.cache
            end
          RUBY
        end
      end

      def install_mount
        route "mount RailsNewadmin::Engine => #{options[:path].inspect}, as: :rails_newadmin" unless @routes.include?("mount RailsNewadmin::Engine")
      end

      def install_migrations
        Dir[Engine.root.join("db/migrate/*.rb")].sort.each do |source|
          name = File.basename(source).sub(/\A\d+_/, "")
          next if Dir[File.join(destination_root, "db/migrate/*_#{name}")].any?
          migration_template File.basename(source), "db/migrate/#{name}"
        end
      end

      def instructions
        say "Next: bin/rails db:migrate; register resources; bin/rails rails_newadmin:permissions:sync; bin/rails rails_newadmin:admin:create"
      end
    end
  end
end
