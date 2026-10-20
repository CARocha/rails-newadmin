# rails-newadmin

Administrador independiente para Rails con la identidad visual de NewAdmin. **Ruby 3.4+; Rails 8.0–8.1.** Alfa de desarrollo `0.1.0.alpha.1`; todavía no está publicada en RubyGems.

[English](README.md) · [Manual en español](docs/es/index.md) · [Verificación y límites](VERIFICATION.md)

Incluye cuentas independientes con primitivas de Rails, sin Devise; permisos por grupos; políticas y consultas con alcance explícito; CRUD; auditoría transaccional; interfaz ES/EN; temas claro, oscuro y automático; y gráficos ECharts locales opcionales. Conserva las paletas y tipografía de django-newadmin.

## Probar en una aplicación Rails completa

Hasta publicarla en RubyGems, añade el repositorio de GitHub al Gemfile de tu aplicación. La rama `main` contiene el desarrollo de la alfa:

```ruby
gem "rails-newadmin", git: "https://github.com/CARocha/rails-newadmin.git", branch: "main", require: "rails/newadmin"
```

```sh
bundle install
bin/rails generate rails_newadmin:install
bin/rails db:migrate
bin/rails generate rails_newadmin:resource Article
bin/rails rails_newadmin:permissions:sync
bin/rails rails_newadmin:admin:create
```

`Article` debe existir. El generador deja la política cerrada y ningún atributo editable: configura ambos siguiendo la [guía de recursos](docs/es/resources.md). Arranca Rails y visita `/admin`. Los modelos nunca se exponen automáticamente y un superusuario también queda sujeto al alcance de su política.

La aplicación consumidora usa assets precompilados con Propshaft; no necesita Node, Sass, Python ni Sphinx. Esas herramientas solo intervienen al desarrollar la gema o generar su documentación.

```sh
bundle install
bundle exec rails db:migrate RAILS_ENV=test
bundle exec rake test
COVERAGE=1 bundle exec rake test
bundle exec rubocop
npm ci
npm run build
```

Consulta [contribución](docs/es/contributing.md), [seguridad](SECURITY.md), [cambios](CHANGELOG.md) y [estado actual](STATUS.md). Producción requiere un almacén compartido y atómico para limitar intentos y un servicio de correo configurado. La integración con un login existente del host, exportaciones, acciones masivas y archivos quedan para etapas posteriores. Esta alfa no es una certificación 1.0.

Licencia BSD-3-Clause; dependencias con sus licencias en [NOTICE](NOTICE).
