require "test_helper"
require "rails/generators"
require "tmpdir"

class GeneratorsTest < ActiveSupport::TestCase
  test "installer copies migrations and mounts once while preserving customization" do
    require "generators/rails_newadmin/install/install_generator"
    Dir.mktmpdir("newadmin-install") do |directory|
      FileUtils.mkdir_p("#{directory}/config/initializers")
      File.write("#{directory}/config/routes.rb", "Rails.application.routes.draw do\nend\n")
      generator = RailsNewadmin::Generators::InstallGenerator
      2.times { generator.start([], destination_root: directory, shell: Thor::Shell::Basic.new) }
      routes = File.read("#{directory}/config/routes.rb")
      assert_equal 1, routes.scan("mount RailsNewadmin::Engine").size
      migrations = Dir["#{directory}/db/migrate/*.rb"]
      assert_equal Dir[RailsNewadmin::Engine.root.join("db/migrate/*.rb")].size, migrations.size
      config = "#{directory}/config/initializers/rails_newadmin.rb"
      File.write(config, "# My customized settings\n")
      generator.start([], destination_root: directory, shell: Thor::Shell::Basic.new)
      assert_equal "# My customized settings\n", File.read(config)
      refute Dir["#{directory}/**/*"].any? { |path| path.include?("user.rb") }
    end
  end

  test "resource generator defaults to denied access and explicit writable fields" do
    require "generators/rails_newadmin/resource/resource_generator"
    Dir.mktmpdir("newadmin-resource") do |directory|
      RailsNewadmin::Generators::ResourceGenerator.start(["Article"], destination_root: directory, shell: Thor::Shell::Basic.new)
      resource = File.read("#{directory}/app/admin/resources/article_resource.rb")
      policy = File.read("#{directory}/app/policies/article_admin_policy.rb")
      assert_includes resource, 'model "Article"'
      assert_includes resource, "permit"
      refute_includes resource, "secret_token"
      assert_includes policy, "RailsNewadmin::Policy"
      refute_includes policy, "relation.all"
    end
  end
end
