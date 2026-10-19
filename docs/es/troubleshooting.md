# Resolver problemas y actualizar

- **403 al abrir un recurso:** revisa permiso `view`, cuenta activa/staff y `allowed?` de la política. Sincronizar no concede permisos.
- **Lista vacía incluso como superusuario:** revisa `scope`; el superusuario no evita el alcance. El generador inicial está cerrado.
- **404 para un ID existente:** puede estar fuera de alcance; no amplíes la consulta para ocultar el problema.
- **422 al guardar:** revisa errores, campos permitidos y relaciones. No desactives CSRF para resolver un token obsoleto; recarga el formulario.
- **409:** otro proceso cambió el registro; vuelve a leer antes de confirmar una modificación o borrado.
- **Error al arrancar producción:** configura un cache compartido para límites. No sustituyas por memoria para hacer pasar el arranque.
- **Correo no llega:** configura host/remitente/SMTP/cola; inspecciona trabajos sin registrar el token.
- **Assets 404:** verifica Propshaft y precompilación; no ejecutes npm en la aplicación como remedio.
- **Versión Rails 8.0 y JSON 3:** el gemspec limita JSON a 2.x porque Active Support 8.0 envía una opción eliminada en JSON 3; respeta el lockfile.

No existe todavía una versión anterior pública desde la que ensayar una actualización. Para futuras alfas: copia de seguridad, consulta changelog, actualiza bundle, instala las nuevas migraciones del engine con `bin/rails rails_newadmin:install:migrations`, migra, sincroniza permisos, recompila assets y verifica políticas/overrides en staging. No borres migraciones aplicadas ni restaures solo el código sobre un esquema incompatible.

Para desinstalar: retira el montaje y la dependencia después de respaldar datos. Las tablas no se borran automáticamente; cualquier eliminación de datos debe ser una decisión explícita del mantenedor.
