# Counts all non-schema/transaction statements, including cached calls, comments and CTEs.
class QueryRecorder
  attr_reader :queries, :cached, :events, :cache_states

  def capture
    @queries, @cached, @events, @cache_states = 0, 0, [], []
    subscriber = lambda do |event|
      next if %w[SCHEMA TRANSACTION].include?(event.payload[:name])
      connection = event.payload[:connection]
      @cache_states << connection.query_cache_enabled if connection&.respond_to?(:query_cache_enabled)
      @queries += 1
      @cached += 1 if event.payload[:cached]
      @events << event
    end
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") { yield }
    self
  end

  def executed = queries - cached
end
