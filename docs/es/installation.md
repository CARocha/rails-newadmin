# Instalación

Esta guía corresponde a la alfa local 0.1.0.alpha.1. Requiere Ruby 3.4+, una aplicación Rails completa 8.0 o 8.1, Active Record, Action Mailer y Propshaft. Los ejemplos parten de un modelo `Article` existente. No se soportan aplicaciones API-only sin añadir la pila HTML/sesiones.

Hasta la publicación, añade la ruta del repositorio al Gemfile:

```ruby
gem "rails-newadmin", path: "/ruta/absoluta/rails-newadmin", require: "rails/newadmin"
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

RubyGems.org es el registro de publicación de gemas, equivalente en propósito a PyPI. El nombre no queda reservado por crear el repositorio o construir un archivo: hay que comprobarlo antes de publicar. No uses aún una instrucción que sugiera que esta alfa ya está disponible públicamente.
