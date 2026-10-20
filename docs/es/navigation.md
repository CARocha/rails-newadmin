# Navegación y assets

El layout del admin carga sus propios bundles locales de Turbo y Stimulus. Tu aplicación conserva su configuración de JavaScript. Al pasar de un layout al otro se realiza una navegación completa; dentro del administrador los enlaces y formularios siguen usando Turbo. Este límite evita ejecutar juntos los runtimes del host y del engine.

## Enlazar desde tu aplicación

Usa el proxy del montaje creado por el instalador y solicita explícitamente una navegación completa:

```erb
<%= link_to "Administración", rails_newadmin.root_path,
      data: { turbo: false } %>
```

No escribas `/admin` a mano si usas otro montaje o prefijo de despliegue. Los assets marcados por el engine también provocan una recarga al entrar con un enlace Turbo normal desde otro layout; conservar `data-turbo="false"` expresa tu intención. El historial de atrás/adelante del navegador sigue disponible.

Para añadir un enlace de regreso en una vista del admin sobrescrita, usa `main_app`:

```erb
<%= link_to "Volver al sitio", main_app.root_path,
      data: { turbo: false } %>
```

El admin también intercepta visitas Turbo que salen de su montaje y hace una navegación completa. En modo host, el botón de salida ya envía un DELETE protegido por CSRF al endpoint del host mediante navegación completa. No lo reemplaces por un enlace GET. Consulta [Autenticación](authentication.md).

## Conservar tu JavaScript existente

Si tu aplicación usa **importmap**, conserva el mapa, los pins y el entrypoint de Turbo/Stimulus en el layout del host:

```erb
<%= javascript_importmap_tags %>
```

Si usa **esbuild**, conserva su bundle compilado en ese layout:

```erb
<%= javascript_include_tag "application", defer: true,
      data: { turbo_track: "reload" } %>
```

Ninguna receta necesita importar `rails_newadmin/application` ni iniciar la aplicación Stimulus del engine. El admin carga sus assets con namespace. Al sobrescribir su layout, conserva esos assets, sus atributos `data-turbo-track="reload"`, los tags CSRF y los metadatos del montaje; no añadas allí el entrypoint del host ni `javascript_importmap_tags`. Copiar el layout del host al admin puede iniciar Turbo dos veces.

Las recetas consumidoras verificadas usan importmap-rails 2.2.2 con Turbo 8.0.23/Stimulus 3.2.2 locales, y un host con esbuild y las mismas versiones. Ambas se comprobaron en Chromium con Propshaft y Rails 8.0/8.1. Esto no certifica cualquier bundler, modificación de Turbo o infraestructura. Rails explica [import maps y bundlers](https://guides.rubyonrails.org/working_with_javascript_in_rails.html); Turbo documenta [assets marcados y límites de navegación](https://turbo.hotwired.dev/handbook/drive).

## Otro montaje y un prefijo de despliegue

Elige el montaje del engine al instalar:

```sh
bin/rails generate rails_newadmin:install --path /control
```

Si toda tu aplicación vive bajo `/portal`, la URL pública del admin será `/portal/control`. En `config/routes.rb` el montaje sigue siendo `/control`: `/portal` corresponde al despliegue de la aplicación. El servidor Rack o proxy debe pasar `SCRIPT_NAME=/portal` y quitar ese prefijo de `PATH_INFO`. Configura de forma consistente la raíz relativa al precompilar y servir:

```sh
RAILS_RELATIVE_URL_ROOT=/portal RAILS_ENV=production bin/rails assets:precompile
RAILS_RELATIVE_URL_ROOT=/portal RAILS_ENV=production bin/rails server
```

La variable no configura un proxy ni monta la aplicación por sí sola. Comprueba las URLs públicas y sirve los assets compilados en `/portal/assets`. La receta verificada usa un mapa de URLs de Rack para `/portal`; si tu proxy elimina el prefijo, configura las variables Rack equivalentes. No dupliques `/portal` en la opción del instalador ni en las rutas del adaptador. Usa `controller.main_app.new_session_path` y `controller.main_app.session_path` para heredar el prefijo de la petición. Las rutas de autenticación deben quedar fuera del montaje del admin; se rechazan segmentos de punto y separadores codificados para evitar redirecciones ambiguas.

## Producción y diagnóstico

La gema incluye assets compilados: no necesita Node para precompilar sus assets ni para servir el admin. La receta esbuild verificada genera el bundle del host directamente antes de precompilar con Rails. El bundler de tu aplicación puede seguir necesitando Node durante su build; por ejemplo, jsbundling-rails puede ejecutar el build JavaScript dentro de `assets:precompile`. Genera primero los assets del host y después precompila con Rails. No elimines el build del host por el hecho de que la gema incluya bundles propios.

Los gráficos se cargan solo cuando el dashboard los declara. Abrir una lista directamente no descarga ECharts. Al salir se liberan gráficos, observadores de tamaño y listeners de tema; al volver se crea una sola instancia actual. Un clic de apariencia debe avanzar un modo y enviar un formulario debe producir una petición.

Ante clics duplicados o avisos de Turbo, revisa los layouts sobrescritos y elimina el entrypoint adicional. Para assets con 404, comprueba Propshaft, precompilación y prefijo antes de cambiar JavaScript. Mantén abiertas la consola y la pestaña de red al probar host → admin → recurso → atrás → host, incluido el cierre de sesión. Consulta [Producción](production.md) para HTTPS, caché y entrega de assets.
