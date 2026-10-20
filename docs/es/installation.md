# Instalación

Esta guía corresponde a la alfa de desarrollo 0.1.0.alpha.1. Requiere Ruby 3.4+, una aplicación Rails completa 8.0 o 8.1, Active Record, Action Mailer y Propshaft. Los ejemplos parten de un modelo `Article` existente. No se soportan aplicaciones API-only sin añadir la pila HTML/sesiones.

Hasta publicarla en RubyGems, instala desde GitHub. La rama `main` contiene el desarrollo de la alfa:

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
bin/rails server
```

El último comando de administración pide email y contraseña en la terminal; no existe ninguna cuenta predeterminada. Instalar dos veces conserva el initializer y no duplica migraciones ni montaje. Para otra ruta usa `--path /control` en la primera instalación. Si la ruta ya existe, el generador pide elegir otra. Comprueba rutas con `bin/rails routes`.

El recurso recién generado está cerrado. Abre su política y sus campos siguiendo [Recursos](resources.md). Visita `/admin` cuando hayas configurado el acceso.

Si recibes un archivo `.gem`, puedes instalarlo en el entorno Ruby activo con `gem install /ruta/rails-newadmin-0.1.0.alpha.1.gem`, declarar esa versión en el Gemfile con `require: "rails/newadmin"` y ejecutar `bundle install --local`. Las dependencias deben estar instaladas o descargarse de RubyGems. La aplicación no necesita npm ni Python.

Esta alfa se instala desde GitHub. `gem install rails-newadmin` requiere una versión publicada en RubyGems.

## Revertir la instalación

Desde la aplicación Rails puedes previsualizar y ejecutar la reversión:

```sh
bin/rails destroy rails_newadmin:install --pretend
bin/rails destroy rails_newadmin:install
```

Se retiran el initializer y el montaje creados por el instalador cuando siguen sin editar. No necesitas repetir `--path` para retirar un montaje generado en otra ruta. Las configuraciones y rutas editadas o preexistentes se conservan y el comando indica que debes revisarlas manualmente. Las instalaciones antiguas que no permiten identificar el origen de esos archivos también se conservan.

**Las migraciones, tablas, cuentas, permisos y datos se conservan siempre.** El comando no ejecuta una reversión de base de datos ni borra modelos, recursos o políticas de tu aplicación. No elimines una migración aplicada como parte de esta limpieza.

Revisa `config/routes.rb`: si el montaje se conservó porque lo personalizaste, retíralo manualmente para deshabilitar el acceso al panel. Antes de quitar la gema del Gemfile, retira también las referencias restantes al engine en la configuración.

Puedes reinstalar con `bin/rails generate rails_newadmin:install` (o `--path /control` para otra ruta). Se reutilizan las migraciones existentes y se conservan las personalizaciones. Repetir la instalación o la reversión no duplica migraciones.
