# Consultas y rendimiento

El listado usa 25 registros por página y limita `per_page` a 100. El autocomplete devuelve hasta 20 opciones por petición. Al editar, el selector puede añadir el valor actual autorizado si no está entre las primeras 20 opciones; esto conserva la selección y no cambia el límite del endpoint de búsqueda.

Las políticas y los alcances siguen aplicándose en todas las consultas. No guardes permisos, identidades ni resultados por usuario en una caché compartida sin una estrategia que respete revocaciones y separación de organizaciones.

## Evitar consultas por cada fila

Las columnas del listado leen atributos de base de datos. Una política que consulta asociaciones para cada registro puede introducir N+1. Declara únicamente las asociaciones que realmente utiliza:

```ruby
class ArticleResource < RailsNewadmin::Resource
  model "Article"
  key "articles"
  columns :id, :title, :status
  fields :title, :status, :category_id
  permit :title, :status, :category_id
  policy "ArticleAdminPolicy"
  includes :category
  relation :category, resource: "categories"
end
```

Registra también el recurso `categories` con su propia política, como explica la [guía de recursos](resources.md).

`includes` en este DSL utiliza `preload` de Active Record para la página acotada; no incorpora automáticamente todas las asociaciones. Las precargas no autorizan recursos ni sustituyen `scope` o `allowed?`. Evita consultas adicionales dentro de la política: una precarga no elimina llamadas independientes como `Category.find(record.category_id)`.

Para asociaciones anidadas, declara la precarga de Active Record en tu alcance, por ejemplo `relation.where(organization_id: organization_id).preload(category: :organization)`. El DSL `includes` admite nombres simples de asociaciones.

Comprueba el número de consultas del recorrido completo, incluidos autorización, layout y políticas por registro. Comparar páginas de 25 y 50 filas ayuda a detectar crecimiento por fila. Cuenta también las consultas servidas por la caché SQL; sus aciertos pueden ocultar un N+1. Consulta la [guía de precargas de Rails](https://guides.rubyonrails.org/active_record_querying.html#preload).

## Observar el coste de las colecciones

Puedes suscribirte al evento local `query.rails_newadmin` desde un initializer:

```ruby
ActiveSupport::Notifications.subscribe("query.rails_newadmin") do |event|
  metadata = event.payload.slice(
    :resource_key, :operation, :page, :per_page, :request_id, :success
  )
  Rails.logger.info(metadata.merge(
    event: "query.rails_newadmin", duration_ms: event.duration.round(2)
  ).to_json)
end
```

| Campo | Significado |
|---|---|
| `resource_key` | Recurso consultado; en relaciones es el recurso de destino |
| `operation` | `list` u `options` |
| `page`, `per_page` | Paginación ya normalizada y limitada |
| `request_id` | Correlación con la petición |
| `success` | La lectura instrumentada terminó correctamente |

La duración del listado comprende la carga de la página, sus precargas y el conteo exacto. En opciones comprende la lectura de opciones y, al editar, la búsqueda de la selección actual. No incluye decisiones previas de autorización/alcance, renderizado ni todas las consultas de una política por fila. Para el tiempo total del servidor, mide la petición completa con la instrumentación de Rails o tu APM.

El evento se emite después de autorizar la colección; no se emite para colecciones denegadas. Conserva el error original si la lectura falla y publica `success: false`, sin añadir mensajes u objetos de excepción, SQL, registros, filtros, contraseñas ni tokens. No envía telemetría remota ni instala un logger automáticamente. Mantén los suscriptores rápidos y evita operaciones de red síncronas; para métricas, agrupa por recurso/operación y no por `request_id`. Otros eventos y logs de Rails tienen sus propios datos y configuración. Consulta [ActiveSupport::Notifications](https://api.rubyonrails.org/v8.1.0/classes/ActiveSupport/Notifications.html).

## Índices, conteos y límites del host

El conteo es exacto y puede costar más en tablas grandes o alcances complejos. La paginación usa offset; las páginas profundas pueden requerir recorrer muchas filas. El orden añade la clave primaria como desempate cuando se ordena por otra columna permitida.

Revisa con `EXPLAIN (ANALYZE, BUFFERS)` las consultas reales de tu aplicación antes de añadir índices. Filtrar por organización y ordenar por ID puede justificar un índice compuesto, según tus datos. La búsqueda por texto utiliza coincidencias que contienen el término; un índice B-tree convencional puede no resolverlas. Define los índices y la estrategia de búsqueda en tu aplicación; la gema no modifica tablas de negocio automáticamente.

Configura y prueba los límites del pool y los timeouts de base de datos según tu despliegue. La gema no fija un `statement_timeout` global ni interrumpe consultas por un plazo propio. Los límites del host pueden afectar a otros procesos que compartan conexión o rol.

Mide latencias con el modo de producción, un conjunto representativo de datos, cachés y concurrencia registrados. Los presupuestos de consultas y tamaños acotados ayudan a evitar regresiones; no garantizan una latencia universal ni sustituyen pruebas de carga en tu aplicación. Los gráficos permanecen en un bundle separado y las páginas sin gráficos no lo solicitan.
