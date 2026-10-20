# Accesibilidad

El administrador incluye enlace «Saltar al contenido», navegación por teclado, foco visible, títulos de página, tablas con cabeceras y errores asociados a los campos. Después de navegar con Turbo, el foco pasa al contenido; una validación rechazada lo lleva al resumen de errores. Activa un enlace del resumen para corregir su campo.

En pantallas estrechas, abre la navegación con el botón de menú. Escape la cierra y devuelve el foco al botón. El menú es una sección desplegable, no un diálogo modal: Tab permite continuar hacia el contenido. Las tablas anchas se desplazan dentro de una región con nombre; enfócala con Tab y utiliza las flechas. Los gráficos ofrecen los mismos datos en «Ver datos del gráfico» y no requieren usar sus tooltips.

En macOS, Safari puede necesitar Opción+Tab o activar la navegación por teclado en los ajustes del sistema/navegador para recorrer todos los controles.

## Apariencia y ampliación

Selecciona claro, oscuro o automático con el botón de apariencia. El modo automático sigue el esquema del sistema. Se respetan las preferencias de movimiento y transparencia reducidos. Puedes ampliar el contenido desde el navegador; las tablas pueden necesitar desplazamiento horizontal dentro de su propia región.

Si personalizas colores, conserva contraste suficiente: 4.5:1 para texto normal y 3:1 para texto grande y los indicadores de controles cuando corresponda. Comprueba también foco, hover, mensajes de error y ambos temas. Consulta [contraste de texto](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) y [reflow a 320 píxeles CSS](https://www.w3.org/WAI/WCAG22/Understanding/reflow.html).

## Recursos y vistas personalizadas

Define nombres comprensibles y traducciones para modelos y atributos. Mantén etiquetas visibles, cabeceras de tabla, nombres para las regiones desplazables y mensajes de validación que indiquen cómo corregir el problema. No elimines los estilos de foco ni conviertas enlaces o botones en elementos sin semántica. Proporciona tablas equivalentes para los gráficos personalizados.

La autenticación del host y las vistas que sobrescribas requieren su propia revisión. Las comprobaciones automatizadas con axe y navegadores ayudan a detectar regresiones, pero no sustituyen una revisión con lectores de pantalla ni constituyen una certificación WCAG. Antes de usarlo en producción, prueba tus recursos y recorridos reales con las tecnologías de asistencia de tus usuarios.
