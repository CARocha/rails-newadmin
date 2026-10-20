# Accounts and authentication

Rails supplies `has_secure_password`, signed tokens, encrypted cookies, CSRF and request rate limiting. Its authentication generator writes application code; it does not provide a complete administration system with groups and policies. This gem builds on those primitives and owns separate `RailsNewadmin::AdminUser` accounts without Devise.

Entry requires an active staff account. `superuser` bypasses group grants, never policy scope. Passwords require 12 characters and obey bcrypt's 72-byte limit. Prefer long passwords from a password manager.

Sessions store only a SHA-256 digest of a random token. The encrypted cookie uses HttpOnly, SameSite=Lax, mount-scoped path and Secure over HTTPS. Defaults are 12-hour absolute lifetime and 30-minute idle timeout. Logout revokes one session; password changes and deactivation revoke all sessions.

```ruby
RailsNewadmin.configure do |config|
  config.session_lifetime = 12.hours
  config.session_idle_timeout = 30.minutes
end
```

Recovery uses 15-minute signed links and a generic request response. Configure a sender, trusted URL host, delivery and Active Job queue. Production links force HTTPS. Query token parameters are filtered by Rails; redact upstream query logs too and avoid analytics on recovery pages.

The default mode is `authentication = :builtin`. An existing application login can instead supply identity through the host mode below. The two modes are explicit: host mode never falls back to builtin credentials.

Account/group screens are included. Non-superuser access managers can manage ordinary accounts but cannot promote accounts or edit superusers. The panel/service protects the final active owner. Direct console/SQL operations remain the maintainer's responsibility and can bypass those safeguards.

## Use an existing Rails login

Host mode keeps passwords, login, recovery, session expiry and logout in your application. The engine stores only administrative status, locale and group memberships in `ActorIdentity`. A signed-in host user gets no admin access until you explicitly provision that identity. No second `AdminUser` or password is needed.

First create an adapter, for example `app/models/newadmin_host_adapter.rb`. This recipe matches the **unmodified Rails 8 authentication generator** (`User`, `Session`, signed `session_id`, GET `/session/new`, DELETE `/session`); adapt it to your actual application. The engine does not run your `ApplicationController` authentication callbacks or automatically populate `Current.user`.

```ruby
class NewadminHostAdapter < RailsNewadmin::HostAuthenticationAdapter
  def current_user(controller:)
    ::Session.find_by(id: controller.request.cookie_jar.signed[:session_id])&.user
  end

  # The generated User has no active column. Check suspension/expiry here
  # if your application supports them; use the same rules as your own login.
  def active?(user:) = user.persisted?
  def login_path(controller:) = controller.main_app.new_session_path
  def logout_path(controller:) = controller.main_app.session_path
end
```

Implement all four public methods with exactly the shown keyword signatures. `current_user` returns `nil` for a guest, or a persisted Active Record model with one scalar primary key (integer/string/UUID). STI uses its base model name. `active?` must return `true` to admit the account. Missing classes, incomplete adapters and invalid configuration raise `RailsNewadmin::ConfigurationError`; adapter failures never enable builtin authentication. Store the adapter **class name string**, so Rails development reloads resolve the current class.

If you use expiring sessions, SSO, MFA or account suspension, call your application's session resolver and checks here. The simple cookie lookup above adds none of those rules. Do not resolve a user from request parameters, email matching or a stale request-global value. Review Rails' [authentication/security guide](https://guides.rubyonrails.org/security.html) and [engine isolation](https://guides.rubyonrails.org/engines.html).

For a new installation, after creating the adapter:

```sh
bin/rails generate rails_newadmin:install --authentication=host --authentication-adapter=NewadminHostAdapter
bin/rails db:migrate
bin/rails rails_newadmin:permissions:sync
```

The installer preserves existing initializers. To switch an installed panel, copy the new engine migration, migrate, then edit the existing initializer and restart:

```sh
bin/rails rails_newadmin:install:migrations
bin/rails db:migrate
```

```ruby
RailsNewadmin.configure do |config|
  config.authentication = :host
  config.authentication_adapter = "NewadminHostAdapter"
end
```

Provision your first owner in `bin/rails console`, using an existing, trusted host account:

```ruby
user = User.find(your_existing_user_id)
identity = RailsNewadmin::ActorIdentity.find_or_initialize_by(
  RailsNewadmin::ActorIdentity.key_for(user)
)
identity.update!(active: true, staff: true, superuser: true, locale: "en")
```

For ordinary staff, set `superuser: false`, create a group with the panel's **Groups** screen, select its permissions, and assign it explicitly in the console:

```ruby
reader = User.find(your_existing_reader_id)
identity = RailsNewadmin::ActorIdentity.find_or_initialize_by(
  RailsNewadmin::ActorIdentity.key_for(reader)
)
identity.update!(active: true, staff: true, superuser: false)
identity.groups = [RailsNewadmin::Group.find(your_group_id)]
```

Identity and membership provisioning currently use the console; this mode has no identity-management form. Builtin account screens, login, password recovery and session-write endpoints return 404. Existing builtin tables/data remain intact. Groups stay available to actors with `admin_access.manage_access` or `superuser`; those grants are privileged. Console changes bypass the builtin panel's final-owner protection: retain an active host owner and a recovery procedure.

Policies receive `RailsNewadmin::HostActor`. Use `actor.user` for your application's relationships and `actor.identity` for admin metadata; `actor.id` is the original user's key. No other user attributes are implicitly delegated. For example, a tenant scope can return `relation.where(organization_id: actor.user.organization_id)`. Action checks and writable-field allowlists still apply, including for owners. If you support both modes, branch explicitly on the actor type in your policies. Audit records use the original host model type/key, not the bridge's ID.

Guests redirect to `login_path`; signed-in users without an active staff identity receive 403. The logout button sends a full-page **DELETE** with Rails CSRF protection directly to `logout_path`: that endpoint must revoke the host session and redirect safely. There is no engine logout callback or GET logout. Both paths must be absolute local paths outside the engine mount (including the deployment prefix if applicable), never external URLs. Configure SSO through local host endpoints. The host login chooses its own post-login destination; add a safe link back to the admin with `data-turbo="false"` if needed. Do not accept an unchecked return URL.

Host session invalidation, identity suspension and permission revocation take effect on the next request. Engine `session_lifetime` and `session_idle_timeout` apply only to builtin sessions. Keep your application's session/MFA/cookie protections. Remove an identity and its memberships when deleting the corresponding host account, never reuse actor keys, and migrate identities deliberately if renaming models or changing primary keys. Switching back to builtin mode requires restoring its configuration and having a valid builtin owner; host identities are not converted into password accounts.

Host identity keys assume a single database/tenant identity namespace. Switching between shards with colliding model names and primary keys is unsupported; do not share this bridge across those namespaces.
