require "io/console"

namespace :rails_newadmin do
  namespace :permissions do
    desc "Synchronize explicit resource permissions without granting them"
    task sync: :environment do
      RailsNewadmin::Permission.sync!
      puts "Permissions synchronized. No grants were changed."
    end
  end

  namespace :admin do
    desc "Create the first administrator interactively, without default credentials"
    task create: :environment do
      abort "Interactive terminal required" unless $stdin.tty?
      print "Email: "
      email = $stdin.gets&.strip
      password = $stdin.getpass("Password (12+ characters): ")
      confirmation = $stdin.getpass("Confirm password: ")
      user = RailsNewadmin::AdminUser.create!(email_address: email, password: password,
        password_confirmation: confirmation, staff: true, superuser: true)
      puts "Administrator created: #{user.email_address}"
    rescue ActiveRecord::RecordInvalid => error
      abort error.record.errors.full_messages.join("; ")
    end
  end
end
