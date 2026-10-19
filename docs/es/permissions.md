# Grupos, permisos y auditoría

Ejecuta `bin/rails rails_newadmin:permissions:sync` después de registrar o quitar recursos. Crea/actualiza los permisos `view`, `create`, `update`, `destroy`, desactiva los huérfanos y no concede ninguno. No se escribe en la base al arrancar para descubrir modelos.

Crea grupos desde el panel, marca permisos y asigna cuentas. Un lector puede tener solo `articles.view`; no podrá escribir aunque envíe directamente un PATCH. La política y su alcance se aplican además del permiso. Los permisos se vuelven a leer en la siguiente petición; la lista usa una instantánea por petición para evitar consultas por fila.

`admin_access.manage_access` abre la gestión de usuarios y grupos, una capacidad privilegiada que puede conceder otros permisos. Solo los superusuarios pueden crear/editar otros superusuarios. Conserva al menos un propietario activo.

La auditoría registra actor, recurso, ID, acción, request ID, fecha y nombres de campos cambiados. No almacena valores previos/nuevos, contraseñas ni cuerpos. La mutación y su evento comparten transacción: si falla el evento, se revierte la mutación. El detalle muestra los últimos 50 eventos del registro.

Define retención, limpieza de sesiones caducadas y acceso a backups según tu aplicación. No hay un servicio remoto de telemetría ni una tarea periódica de limpieza habilitada automáticamente.
