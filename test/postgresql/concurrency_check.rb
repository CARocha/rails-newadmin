# Separate nontransactional PostgreSQL check on a disposable test database only.
ENV["RAILS_ENV"] = "test"
require_relative "../dummy/config/environment"
raise "PostgreSQL required" unless ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
require "securerandom"
begin
users = 2.times.map do
  RailsNewadmin::AdminUser.create!(email_address: "race-#{SecureRandom.hex(8)}@example.test", password: SecureRandom.base64(24), staff: true, superuser: true)
end
raise "Use an empty disposable database" unless RailsNewadmin::AdminUser.where(active: true, staff: true, superuser: true).count == 2
ready = Queue.new
start = Queue.new
outcomes = Queue.new
threads = users.map do |user|
  Thread.new do
    ActiveRecord::Base.connection_pool.with_connection do
      ready << true
      start.pop
      begin
        actor = RailsNewadmin::AdminUser.find(user.id)
        RailsNewadmin::AccessManagement.new(actor).update_user!(actor, { active: false })
        outcomes << :updated
      rescue RailsNewadmin::AccessManagement::LastSuperuser
        outcomes << :protected
      end
    end
  end
end
2.times { ready.pop }
2.times { start << true }
threads.each(&:value)
actual = 2.times.map { outcomes.pop }.sort
raise "Final owner lost: #{actual.inspect}" unless actual == [ :protected, :updated ] && RailsNewadmin::AdminUser.where(id: users.map(&:id), active: true).count == 1
puts "Concurrent attempts serialize and retain exactly one active owner"
ensure
  if defined?(users) && users
    RailsNewadmin::AuditEvent.where(actor_type: "RailsNewadmin::AdminUser", actor_id: users.map { |user| user.id.to_s }).delete_all
    users.each(&:destroy!)
  end
end
