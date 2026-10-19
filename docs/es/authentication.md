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

La alfa solo acepta `authentication = :builtin`. El adaptador del login existente del host y la identidad compartida siguen pendientes; seleccionar `:host` produce un error explícito. Un `User` del host puede coexistir porque el engine usa sus propias clases y tablas.

Los usuarios/grupos se gestionan desde el panel. Un gestor de accesos no superusuario puede administrar cuentas ordinarias, pero no ascender cuentas ni editar superusuarios. No puede desactivarse el último superusuario activo mediante el servicio/panel. La consola y operaciones SQL son responsabilidad del mantenedor y pueden saltarse estas reglas.
