# Cuentas y autenticación

Rails proporciona `has_secure_password`, tokens firmados, cookies cifradas, CSRF y el limitador de peticiones. Su generador de autenticación crea código en una aplicación; no instala un administrador completo con grupos y permisos. Esta gema usa esas primitivas y mantiene cuentas independientes `RailsNewadmin::AdminUser` sin depender de Devise.

Solo una cuenta activa con `staff` puede entrar. `superuser` evita las concesiones por grupo, pero no las políticas. La contraseña tiene mínimo 12 caracteres y el límite de bcrypt de 72 bytes. Usa contraseñas largas generadas por un gestor.

Las sesiones guardan un hash SHA-256 de un token aleatorio; la cookie contiene el token cifrado, con HttpOnly, SameSite=Lax, ruta del montaje y Secure bajo HTTPS. Caducan a las 12 horas o 30 minutos de inactividad por defecto. Salir revoca la sesión; cambiar la contraseña o desactivar la cuenta revoca todas sus sesiones.

```ruby
RailsNewadmin.configure do |config|
  config.session_lifetime = 12.hours
  config.session_idle_timeout = 30.minutes
end
```

Recuperación usa enlaces firmados de 15 minutos y una respuesta genérica al solicitar correo. Configura remitente, host de confianza y entrega/cola de Action Mailer. En producción los enlaces se generan con HTTPS. Los tokens van en un parámetro filtrado; también debes redactar query strings en el proxy y evitar analítica en estas páginas.

El modo predeterminado es `authentication = :builtin`. También puedes integrar el login existente de tu aplicación mediante el modo host descrito abajo. Los modos son explícitos: host nunca recurre a credenciales propias de la gema.

Los usuarios/grupos se gestionan desde el panel. Un gestor de accesos no superusuario puede administrar cuentas ordinarias, pero no ascender cuentas ni editar superusuarios. No puede desactivarse el último superusuario activo mediante el servicio/panel. La consola y operaciones SQL son responsabilidad del mantenedor y pueden saltarse estas reglas.

## Usar el login existente de Rails

El modo host deja contraseñas, login, recuperación, caducidad y cierre de sesión en tu aplicación. El engine guarda únicamente estado administrativo, idioma y membresías en `ActorIdentity`. Tener una sesión del host no concede acceso al panel: debes habilitar esa identidad expresamente. No necesitas otro `AdminUser` ni otra contraseña.

Crea primero un adaptador, por ejemplo `app/models/newadmin_host_adapter.rb`. Esta receta corresponde al **generador de autenticación de Rails 8 sin modificar** (`User`, `Session`, cookie firmada `session_id`, GET `/session/new`, DELETE `/session`); adáptala a tu aplicación. El engine no ejecuta los callbacks de autenticación de tu `ApplicationController` ni rellena automáticamente `Current.user`.

```ruby
class NewadminHostAdapter < RailsNewadmin::HostAuthenticationAdapter
  def current_user(controller:)
    ::Session.find_by(id: controller.request.cookie_jar.signed[:session_id])&.user
  end

  # El User generado no tiene columna active. Comprueba aquí suspensiones
  # y caducidad si existen, siguiendo las mismas reglas que tu login.
  def active?(user:) = user.persisted?
  def login_path(controller:) = controller.main_app.new_session_path
  def logout_path(controller:) = controller.main_app.session_path
end
```

Implementa los cuatro métodos públicos con exactamente las firmas de argumentos mostradas. `current_user` devuelve `nil` para un visitante o un modelo Active Record persistido con una sola clave primaria (entero/string/UUID). STI usa el nombre del modelo base. `active?` debe devolver `true` para admitir la cuenta. Si falta la clase, un método o la configuración, se produce `RailsNewadmin::ConfigurationError`; un fallo nunca activa el login propio. Configura el **nombre de clase como string**, para resolver la clase vigente al recargar en desarrollo.

Si tienes sesiones con caducidad, SSO, MFA o suspensión de cuentas, llama aquí al servicio de sesiones y a las comprobaciones de tu aplicación. La consulta de cookie del ejemplo no añade esas reglas. No obtengas usuarios de parámetros, coincidencias de email o valores globales antiguos. Consulta las guías de [autenticación y seguridad de Rails](https://guides.rubyonrails.org/security.html) y [aislamiento de engines](https://guides.rubyonrails.org/engines.html).

En una instalación nueva, después de crear el adaptador:

```sh
bin/rails generate rails_newadmin:install --authentication=host --authentication-adapter=NewadminHostAdapter
bin/rails db:migrate
bin/rails rails_newadmin:permissions:sync
```

El instalador conserva los inicializadores existentes. Para cambiar un panel ya instalado, copia la migración nueva, migra y después edita el inicializador y reinicia:

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

Habilita al primer propietario desde `bin/rails console`, usando una cuenta existente y de confianza:

```ruby
user = User.find(id_de_tu_usuario_existente)
identity = RailsNewadmin::ActorIdentity.find_or_initialize_by(
  RailsNewadmin::ActorIdentity.key_for(user)
)
identity.update!(active: true, staff: true, superuser: true, locale: "es")
```

Para personal ordinario usa `superuser: false`. Crea un grupo en la pantalla **Grupos** del panel, selecciona sus permisos y asígnalo expresamente desde la consola:

```ruby
reader = User.find(id_de_tu_lector_existente)
identity = RailsNewadmin::ActorIdentity.find_or_initialize_by(
  RailsNewadmin::ActorIdentity.key_for(reader)
)
identity.update!(active: true, staff: true, superuser: false)
identity.groups = [RailsNewadmin::Group.find(id_de_tu_grupo)]
```

Por ahora las identidades y sus membresías se habilitan desde la consola; este modo no incluye formulario para administrarlas. Las pantallas de cuentas propias, login, recuperación y escritura de sesiones del engine devuelven 404. Sus tablas y datos anteriores se conservan. Los grupos siguen disponibles para actores con `admin_access.manage_access` o `superuser`; esas concesiones son privilegiadas. La consola no protege al último propietario como lo hace el panel builtin: conserva un propietario activo del host y un procedimiento de recuperación.

Las políticas reciben un `RailsNewadmin::HostActor`. Usa `actor.user` para las relaciones de tu aplicación y `actor.identity` para los metadatos administrativos; `actor.id` es la clave original del usuario. No se delegan otros atributos implícitamente. Por ejemplo, un scope por organización puede devolver `relation.where(organization_id: actor.user.organization_id)`. Las comprobaciones de acción y los campos permitidos siguen aplicándose, incluso al propietario. Para admitir ambos modos, distingue explícitamente el tipo de actor en tus políticas. La auditoría registra el tipo/clave del usuario original, no el ID del puente.

Los visitantes se redirigen a `login_path`; un usuario autenticado sin identidad activa y staff recibe 403. El botón de salida envía un **DELETE** con protección CSRF de Rails y navegación completa directamente a `logout_path`: ese endpoint debe revocar la sesión del host y redirigir de forma segura. No hay callback de logout del engine ni salida por GET. Ambas rutas deben ser locales y absolutas, fuera del montaje del engine e incluir el prefijo del despliegue si corresponde; no se aceptan URLs externas. Integra SSO mediante endpoints locales del host. Tu login decide el destino al autenticar; si hace falta, añade un enlace seguro al panel con `data-turbo="false"`. No aceptes una URL de retorno sin validarla.

Revocar la sesión del host, desactivar la identidad o retirar permisos surte efecto en la siguiente petición. `session_lifetime` y `session_idle_timeout` de la gema solo afectan a sesiones builtin. Conserva las protecciones de sesión, MFA y cookies de tu aplicación. Elimina la identidad y sus membresías al borrar la cuenta correspondiente; no reutilices claves de actores y migra identidades expresamente si renombras modelos o cambias claves primarias. Volver a builtin exige restaurar su configuración y disponer de un propietario builtin válido; las identidades del host no se convierten en cuentas con contraseña.
