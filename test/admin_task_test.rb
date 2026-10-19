require "test_helper"
require "rake"
require "stringio"

class AdminTaskTest < ActiveSupport::TestCase
  class Terminal
    def initialize(email, password)
      @email, @password = email, password
    end
    def tty? = true
    def gets = "#{@email}\n"
    def getpass(_prompt) = @password
  end

  test "first administrator task prompts for credentials without printing password" do
    load RailsNewadmin::Engine.root.join("lib/tasks/rails_newadmin.rake") unless Rake::Task.task_defined?("rails_newadmin:admin:create")
    Rake::Task.define_task(:environment) unless Rake::Task.task_defined?(:environment)
    original = $stdin
    $stdin = Terminal.new("first-owner@example.test", "a long interactive password")
    output, = capture_io { Rake::Task["rails_newadmin:admin:create"].invoke }
    owner = RailsNewadmin::AdminUser.find_by!(email_address: "first-owner@example.test")
    assert owner.administrative?
    assert owner.superuser?
    assert owner.authenticate("a long interactive password")
    refute_includes output, "a long interactive password"
    Rake::Task["rails_newadmin:admin:create"].reenable
    assert_raises(SystemExit) { capture_io { Rake::Task["rails_newadmin:admin:create"].invoke } }
    assert_equal 1, RailsNewadmin::AdminUser.where(email_address: owner.email_address).count
  ensure
    $stdin = original
    Rake::Task["rails_newadmin:admin:create"].reenable
  end
end
