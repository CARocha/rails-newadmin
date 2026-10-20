# Security / Seguridad

This is an unreleased alpha. Do not report vulnerabilities in public issue details. Until a dedicated private reporting channel exists, contact the maintainer privately through an independently verified channel. Do not include credentials or real user records in reports.

Alfa sin publicar. Comunica vulnerabilidades por un canal privado y verificado del mantenedor, sin credenciales ni registros reales. Todavía no hay un canal de seguridad específico publicado.

Authentication uses Rails primitives, but this engine owns its sessions and authorization. A generated Rails authentication flow does not supply Django-like groups or resource policies automatically. Review every resource policy and attribute list. Superuser bypasses group grants only, never the policy. `manage_access` can grant permissions and is highly privileged. Never use `--single-site` on tenant-separated data without replacing its policy.

Use HTTPS, correctly configured trusted proxies, a shared atomic rate-limit cache, redacted query/access logs, encrypted backups and reliable mail delivery in production. Recovery URLs contain a token: redact query strings in upstream logs, never track them with analytics. Rails parameter filters cover password/token inside Rails, not every proxy.

Sessions have 12-hour absolute and 30-minute idle defaults; password changes and deactivation revoke them. Audit stores field names and identifiers, not changed values. Define an app-specific retention and cleanup job for audit and expired session rows; this alpha does not schedule deletion for you.

No claim of an external penetration test, MFA, compliance certification, cross-browser WCAG certification or production readiness is made.
