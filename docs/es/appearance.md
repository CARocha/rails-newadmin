# Apariencia e idioma

El diseño porta los tokens de django-newadmin: fondo claro `#f8f9ff`, superficie blanca, texto `#0b1c30`; modo oscuro con fondo `#11161d` y texto `#eaf0f8`. Usa la tipografía de sistema Segoe UI/system-ui y componentes Bootstrap seleccionados, compilados dentro de la gema. No hay fuentes ni CDNs obligatorios.

```ruby
RailsNewadmin.configure do |config|
  config.site_title = "Mi administración"
  config.default_mode = :auto # :light, :dark
  config.default_locale = :es
  config.available_locales = [:es, :en]
end
```

El control de apariencia alterna auto/claro/oscuro y conserva la preferencia local. ES/EN usa una cookie acotada al montaje y `I18n.with_locale` por petición. Traduce nombres de modelos y atributos con las convenciones de Rails; los valores del negocio no se traducen automáticamente.

Puedes sobrescribir variables `--newadmin-*` desde una hoja propia cargada después del CSS del engine. Editar los archivos precompilados de la gema dificulta las actualizaciones; personaliza tokens o vistas de forma explícita. La capa visual está bajo `.newadmin-*`, aunque el diseño de un host con assets propios requiere comprobar la frontera de navegación y sus overrides.

Hay etiquetas, foco visible, mensajes de error, tablas con encabezados y reflow móvil. No se declara una certificación WCAG ni compatibilidad verificada con todos los lectores de pantalla y navegadores.
