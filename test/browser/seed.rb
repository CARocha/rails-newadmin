require "json"
raise "Node unexpectedly available" if system("command -v node >/dev/null 2>&1")
raise "Consumer loaded source checkout" unless RailsNewadmin::Engine.root.realpath.to_s == File.realpath(ENV.fetch("PACKAGED_ROOT"))
password = SecureRandom.base64(24)
user = User.create!(email_address: "navigation-#{SecureRandom.hex(8)}@example.test", password: password)
RailsNewadmin::ActorIdentity.create!(**RailsNewadmin::ActorIdentity.key_for(user), active: true, staff: true, superuser: true)
Article.create!(title: "Navigation article", status: "draft")
File.write(ENV.fetch("NAVIGATION_CREDENTIALS"), JSON.generate(email: user.email_address, password: password))
