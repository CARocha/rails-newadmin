# rails-newadmin

Administrador independiente para Rails con la identidad visual de NewAdmin. **Ruby 3.4+ · Rails 8.0–8.1**. Alfa de desarrollo `0.1.0.alpha.1`, todavía sin publicar en RubyGems.

[English](README.md) · [Manual de uso](docs/es/index.md)

Administra recursos Active Record con cuentas independientes o el login existente de tu aplicación, permisos por grupos, políticas con alcance, CRUD e historial de auditoría. Incluye interfaz ES/EN, apariencia clara/oscura/automática y dashboards opcionales con gráficos locales. La autenticación usa primitivas de Rails sin Devise.

## Instalar

Añade el repositorio de GitHub al Gemfile de tu aplicación:

```ruby
gem "rails-newadmin", git: "https://github.com/CARocha/rails-newadmin.git", branch: "main", require: "rails/newadmin"
```

La rama `main` contiene el desarrollo de la alfa. Usa una aplicación Rails completa con Active Record, Action Mailer y Propshaft.

```sh
bundle install
bin/rails generate rails_newadmin:install
bin/rails db:migrate
bin/rails generate rails_newadmin:resource Article
bin/rails rails_newadmin:permissions:sync
bin/rails rails_newadmin:admin:create
```

`Article` debe existir. La tarea de cuentas pide las credenciales en la terminal; no hay cuentas predeterminadas. El recurso generado empieza con la política cerrada y ningún campo editable. Configura su [política y campos](docs/es/resources.md), arranca Rails y visita `/admin`. Los modelos nunca se exponen automáticamente y los superusuarios también están sujetos al alcance de las políticas.

La aplicación usa assets empaquetados y no necesita Node, Sass, Python ni Sphinx.

## Configurar

El instalador crea `config/initializers/rails_newadmin.rb`:

```ruby
RailsNewadmin.configure do |config|
  config.site_title = "Mi administración"
  config.default_locale = :es
  config.default_mode = :auto
end
```

- [Instalación y rutas de montaje](docs/es/installation.md)
- [Recursos, políticas y relaciones](docs/es/resources.md)
- [Cuentas y recuperación de contraseña](docs/es/authentication.md)
- [Grupos, permisos y auditoría](docs/es/permissions.md)
- [Apariencia e idioma](docs/es/appearance.md)
- [Dashboards y gráficos](docs/es/dashboards.md)
- [Navegación, importmap/esbuild y prefijos de despliegue](docs/es/navigation.md)
- [Teclado, tablas, validación y personalización accesible](docs/es/accessibility.md)
- [Precargas, consultas y observación del rendimiento](docs/es/performance.md)
- [Configuración de producción](docs/es/production.md)
- [Resolución de problemas y actualizaciones](docs/es/troubleshooting.md)

Producción requiere HTTPS, un almacén compartido con incremento atómico para limitar intentos y entrega de correo configurada. Puedes elegir cuentas propias o un [adaptador al login del host](docs/es/authentication.md#usar-el-login-existente-de-rails), con membresías separadas y sin otra contraseña. No incluye exportaciones, acciones masivas ni subida de archivos.

[Seguridad](SECURITY.md) · [Cambios](CHANGELOG.md) · [Licencia BSD-3-Clause](LICENSE). Los componentes incluidos conservan sus licencias; consulta [NOTICE](NOTICE).
