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

The alpha supports only `authentication = :builtin`. A host-login adapter and identity bridge remain pending; `:host` raises an explicit configuration error. Existing host `User` models can coexist because this engine owns separate namespaced classes and tables.

Account/group screens are included. Non-superuser access managers can manage ordinary accounts but cannot promote accounts or edit superusers. The panel/service protects the final active owner. Direct console/SQL operations remain the maintainer's responsibility and can bypass those safeguards.
