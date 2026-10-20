# Changelog / Cambios

## 0.1.0.alpha.1 — unreleased / sin publicar

- Mountable administration engine for Ruby >=3.4 and Rails 8.0/8.1.
- Importmap/esbuild host navigation verified with real packaged production apps, alternate mount, deployment prefix, history, CRUD and chart/listener cleanup; host authentication rejects ambiguous dot-segment paths.
- Explicit existing-host authentication adapter, default-deny identity/group bridge without duplicate passwords, native host logout and scoped audit.
- Independent native authentication, CSRF, expiring/revocable sessions and recovery.
- Explicit resources, default-deny scoped policies, group grants and access management.
- CRUD, bounded relation search, optimistic edits, atomic field-name audit.
- NewAdmin palettes, local assets, ES/EN, responsive layout, optional scoped charts.
- Install/resource generators and bilingual Sphinx documentation.
- Safe installer reversal preserves customized files, migration history and data; install/destroy/reinstall is verified on a packaged application.

La reversión del instalador conserva personalizaciones, migraciones y datos. Se puede previsualizar con `bin/rails destroy rails_newadmin:install --pretend`.

Administrador independiente con autenticación nativa, permisos explícitos, CRUD acotado, auditoría, estilos NewAdmin, generadores y manual bilingüe. Consulta las guías de instalación y configuración para usar esta versión.
