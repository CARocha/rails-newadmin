require "test_helper"
require_relative "support/query_recorder"

class QueryRecorderTest < ActiveSupport::TestCase
  test "commented statements and CTEs are counted instead of silently ignored" do
    recorder = QueryRecorder.new.capture do
      ActiveRecord::Base.connection.select_value("/* budget marker */ SELECT 1")
      ActiveRecord::Base.connection.select_value("WITH budget_values AS (SELECT 1 AS value) SELECT value FROM budget_values")
    end
    assert_equal 2, recorder.queries
    assert_equal 2, recorder.executed
  end
end
