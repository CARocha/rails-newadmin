require "test_helper"
require "tmpdir"
require_relative "browser/packaged_navigation"

class NavigationHarnessTest < ActiveSupport::TestCase
  test "browser driver finds an executable Node directly through PATH" do
    assert_respond_to PackagedNavigation, :node_executable
    Dir.mktmpdir("navigation-path") do |directory|
      executable = File.join(directory, "node")
      File.write(executable, "test-only executable placeholder")
      File.chmod(0o755, executable)
      with_path(directory) { assert_equal executable, PackagedNavigation.node_executable }
    end
  end

  test "missing and non-executable Node fail with an actionable message" do
    assert_respond_to PackagedNavigation, :node_executable
    Dir.mktmpdir("navigation-path") do |directory|
      File.write(File.join(directory, "node"), "not executable")
      File.chmod(0o644, File.join(directory, "node"))
      with_path(directory) do
        error = assert_raises(RuntimeError) { PackagedNavigation.node_executable }
        assert_match "Node required for the browser driver", error.message
      end
    end
  end

  private

  def with_path(value)
    original = ENV["PATH"]
    ENV["PATH"] = value
    yield
  ensure
    ENV["PATH"] = original
  end
end
