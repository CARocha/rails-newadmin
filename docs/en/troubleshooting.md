# Troubleshooting and upgrades

- **403 opening a resource:** check `view` grant, active/staff account and policy `allowed?`. Permission sync grants nothing.
- **Empty list as superuser:** inspect `scope`; superusers do not bypass it. The generated policy starts closed.
- **404 for an existing ID:** it may be outside scope; do not widen queries to conceal the cause.
- **422 on save:** inspect errors, writable fields and relations. Do not disable CSRF to fix a stale token; reload the form.
- **409:** another process changed the record; reread before editing or confirming deletion.
- **Production boot error:** configure shared rate-limit storage, rather than substituting process memory.
- **Missing recovery email:** configure trusted host/sender/SMTP/queue; inspect jobs without logging tokens.
- **Assets 404:** check Propshaft and precompilation; consumers should not need npm to fix this.
- **Rails 8.0 with JSON 3:** the gemspec holds JSON to 2.x because Active Support 8.0 sends an option removed in JSON 3. Respect the lockfile.

There is no prior public version for a real upgrade rehearsal yet. For future alphas: back up, read the changelog, update the bundle, copy new engine migrations with `bin/rails rails_newadmin:install:migrations`, migrate, sync permissions, precompile and check policies/overrides in staging. Do not delete applied migrations or restore only old code over an incompatible schema.

To remove the integration, follow [Reverse the installation](installation.md#reverse-the-installation). `bin/rails destroy rails_newadmin:install` retains migrations and data, removing only unchanged generated entries. Review preserved files before removing the dependency.

With host authentication, a 403 after successful login means the host account is inactive or its `ActorIdentity` is missing/inactive/nonstaff. Check the adapter and grants; signing in alone never creates an admin identity. Builtin login/recovery/account URLs return 404 by design. Incomplete adapters cause an explicit configuration error; review all four method signatures.
