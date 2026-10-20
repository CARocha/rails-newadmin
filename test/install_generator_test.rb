require "test_helper"
require "rails/generators"
require "generators/rails_newadmin/install/install_generator"
require "tmpdir"

class InstallGeneratorTest < ActiveSupport::TestCase
  HOST_ROUTES = "Rails.application.routes.draw do\n  get \"/host\", to: \"home#index\"\nend\n"

  test "destroy reverses an unchanged alternate mount and initializer while retaining migrations" do
    with_app do |directory|
      run_generator(directory, [ "--path", "/staff/admin" ])
      migrations = snapshot(directory).select { |path, _| path.start_with?("db/migrate/") }
      assert_equal 3, migrations.size
      output = run_generator(directory, [], behavior: :revoke)
      refute_match(/edited or pre-existing RailsNewadmin::Engine mount/, output)
      refute File.exist?("#{directory}/config/initializers/rails_newadmin.rb")
      assert_equal HOST_ROUTES, File.read("#{directory}/config/routes.rb")
      assert_equal migrations, snapshot(directory).select { |path, _| path.start_with?("db/migrate/") }
      first = snapshot(directory)
      run_generator(directory, [], behavior: :revoke)
      assert_equal first, snapshot(directory)
      run_generator(directory)
      assert_equal 3, Dir["#{directory}/db/migrate/*.rb"].size
      assert_equal 1, File.read("#{directory}/config/routes.rb").scan(/^  mount RailsNewadmin::Engine/).size
    end
  end

  test "destroy preserves an edited initializer and an edited mount path" do
    with_app do |directory|
      run_generator(directory)
      config = "#{directory}/config/initializers/rails_newadmin.rb"
      File.write(config, File.read(config).sub('"NewAdmin"', '"My administration"'))
      routes = "#{directory}/config/routes.rb"
      File.write(routes, File.read(routes).sub('=> "/admin"', '=> "/staff"'))
      before = snapshot(directory)
      output = run_generator(directory, [], behavior: :revoke)
      assert_equal before, snapshot(directory)
      assert_match(/preserve/, output)
    end
  end

  test "preexisting unmarked configuration and mount remain untouched" do
    with_app do |directory|
      FileUtils.mkdir_p("#{directory}/config/initializers")
      File.write("#{directory}/config/initializers/rails_newadmin.rb", "# Existing settings\n")
      existing = HOST_ROUTES.sub("  get", "  mount RailsNewadmin::Engine => \"/admin\", as: :rails_newadmin\n  get")
      File.write("#{directory}/config/routes.rb", existing)
      run_generator(directory)
      before = snapshot(directory)
      run_generator(directory, [], behavior: :revoke)
      assert_equal before, snapshot(directory)
    end
  end

  test "path and helper conflicts fail before any generated files are written" do
    [ 'get "/admin", to: "home#index"', 'get "admin", to: "home#index"', 'get "/admin(.:format)", to: "home#index"', 'namespace :admin do; get "/reports", to: "home#index"; end', 'scope :admin do; get "/reports", to: "home#index"; end', 'get :admin, to: "home#index"', 'get "/admin/users", to: "home#index"', 'get "/another", to: "home#index", as: :rails_newadmin', 'get "/another", :to => "home#index", :as => :rails_newadmin' ].each do |entry|
      with_app do |directory|
        File.write("#{directory}/config/routes.rb", HOST_ROUTES.sub("  get", "  #{entry}\n  get"))
        before = snapshot(directory)
        assert_raises(Thor::Error) { run_generator(directory) }
        assert_equal before, snapshot(directory)
      end
    end
  end

  test "commented examples do not hide the mount or cause a false path conflict" do
    with_app do |directory|
      File.write("#{directory}/config/routes.rb", HOST_ROUTES.sub("  get", "  # mount RailsNewadmin::Engine => \"/admin\", as: :rails_newadmin\n  get"))
      run_generator(directory)
      assert_equal 1, File.read("#{directory}/config/routes.rb").scan(/^  mount RailsNewadmin::Engine/).size
    end
  end

  test "previewing destruction makes no filesystem changes" do
    with_app do |directory|
      run_generator(directory)
      before = snapshot(directory)
      run_generator(directory, [ "--pretend" ], behavior: :revoke)
      assert_equal before, snapshot(directory)
    end
  end

  test "invalid options are rejected before writing configuration" do
    [ [ "--path", "../admin" ], [ "--authentication", "host" ] ].each do |arguments|
      with_app do |directory|
        before = snapshot(directory)
        assert_raises(Thor::Error) { run_generator(directory, arguments) }
        assert_equal before, snapshot(directory)
      end
    end
  end

  test "destroy removes an unchanged mount while preserving edited settings and migrations" do
    with_app do |directory|
      run_generator(directory)
      config = "#{directory}/config/initializers/rails_newadmin.rb"
      File.write(config, "# Custom settings\n")
      migration = Dir["#{directory}/db/migrate/*.rb"].first
      File.write(migration, File.read(migration) + "# Custom migration\n")
      before = File.binread(migration)
      run_generator(directory)
      assert_equal before, File.binread(migration)
      run_generator(directory, [], behavior: :revoke)
      assert_equal "# Custom settings\n", File.read(config)
      assert_equal HOST_ROUTES, File.read("#{directory}/config/routes.rb")
      assert_equal before, File.binread(migration)
    end
  end

  test "previewing installation writes no files" do
    with_app do |directory|
      before = snapshot(directory)
      run_generator(directory, [ "--pretend" ])
      assert_equal before, snapshot(directory)
    end
  end

  test "an existing inline mount is preserved without inserting a second engine" do
    with_app do |directory|
      existing = HOST_ROUTES.sub("  get", '  constraints(host: "example.test") { mount RailsNewadmin::Engine => "/staff" }' + "\n  get")
      File.write("#{directory}/config/routes.rb", existing)
      run_generator(directory)
      assert_equal existing, File.read("#{directory}/config/routes.rb")
      run_generator(directory, [], behavior: :revoke)
      assert_equal existing, File.read("#{directory}/config/routes.rb")
    end
  end

  test "Ruby block-commented mounts are not treated as active mounts" do
    with_app do |directory|
      commented = HOST_ROUTES.sub("  get", "=begin\nmount RailsNewadmin::Engine => \"/admin\"\n=end\n  get")
      File.write("#{directory}/config/routes.rb", commented)
      run_generator(directory)
      assert_equal 1, File.read("#{directory}/config/routes.rb").scan(/^  mount RailsNewadmin::Engine/).size
    end
  end

  test "destroy preserves a generated mount that was moved into a block comment" do
    with_app do |directory|
      run_generator(directory)
      path = "#{directory}/config/routes.rb"
      routes = File.read(path)
      mount = routes.lines.find { |line| line.start_with?("  mount") }
      routes = routes.sub(mount, "=begin\n#{mount}=end\n")
      File.write(path, routes)
      run_generator(directory, [], behavior: :revoke)
      assert_equal routes, File.read(path)
    end
  end

  private

  def with_app
    Dir.mktmpdir("newadmin-install") do |directory|
      FileUtils.mkdir_p("#{directory}/config")
      File.write("#{directory}/config/routes.rb", HOST_ROUTES)
      yield directory
    end
  end

  def run_generator(directory, arguments = [], behavior: :invoke)
    output, = capture_io do
      RailsNewadmin::Generators::InstallGenerator.start(arguments, destination_root: directory,
        behavior: behavior, debug: true, shell: Thor::Shell::Basic.new)
    end
    output
  end

  def snapshot(directory)
    Dir["#{directory}/**/*"].select { |path| File.file?(path) }.to_h { |path| [ path.delete_prefix("#{directory}/"), File.binread(path) ] }
  end
end
