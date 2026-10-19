# Groups, permissions and audit

Run `bin/rails rails_newadmin:permissions:sync` after adding/removing resources. It synchronizes `view`, `create`, `update`, `destroy`, deactivates orphan permissions and grants nothing. Boot does not write model-discovery permissions to the database.

Create groups in the panel, select permissions and assign accounts. A reader with only `articles.view` cannot write through a direct PATCH. Policy actions and scopes are additional requirements. Grants are reread on the next request; lists use a request-local snapshot to avoid per-row permission queries.

`admin_access.manage_access` opens users/groups management and can grant other capabilities. Treat it as privileged. Only superusers may create/edit other superusers. Keep an active owner.

Audit events contain actor/resource identifiers, action, request ID, timestamp and changed field names. They do not contain before/after values, passwords or bodies. Mutation and audit share a transaction: audit failure rolls the mutation back. Record details show up to 50 recent events.

Define audit retention, expired-session cleanup and backup access for your application. No remote telemetry or automatic periodic cleanup service is enabled.
