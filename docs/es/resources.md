# Recursos y políticas

Declara recursos en `app/admin/resources` y políticas en `app/policies`. Usa nombres de clases como strings para permitir recargas. No hay descubrimiento automático de modelos.

```ruby
class ArticleResource < RailsNewadmin::Resource
  model "Article"
  key "articles"
  columns :id, :title, :status, :updated_at
  fields :title, :body, :status
  permit :title, :body, :status
  search :title
  filters :status
  policy "ArticleAdminPolicy"
end
```

Las listas controlan presentación, búsqueda, filtros y escritura por separado. `permit` no basta: se intersecta con `fields` y con los atributos devueltos por la política. Nunca incluyas hashes de contraseñas, secretos o tokens. Las columnas deben ser atributos reales de Active Record; métodos calculados y claves primarias compuestas no forman parte del contrato de esta alfa.

Solo para una aplicación cuyos datos sean compartidos por todo el personal autorizado, puedes usar esta política:

```ruby
class ArticleAdminPolicy < RailsNewadmin::Policy
  def allowed?(actor:, action:, record: nil) = true
  def scope(actor:, relation:) = relation.all
  def permitted_attributes(actor:, action:, record: nil) = resource.permitted_fields
end
```

Equivale a generar `Article --single-site --permit title body status`. Este opt-in abre el alcance a toda la tabla, aunque los permisos de grupo siguen siendo necesarios. La política base devuelve false, `none` y ningún atributo.

Para datos separados por organización, mantén el generador cerrado y escribe un alcance como este; `AdminProfile` y `organization_id` son modelos/campos de tu aplicación, no de la gema:

```ruby
class ArticleAdminPolicy < RailsNewadmin::Policy
  def allowed?(actor:, action:, record: nil) = true
  def scope(actor:, relation:)
    organization_id = AdminProfile.find_by(admin_user_id: actor.id)&.organization_id
    organization_id ? relation.where(organization_id: organization_id) : relation.none
  end
  def permitted_attributes(actor:, action:, record: nil) = resource.permitted_fields
end
```

El alcance también restringe a superusuarios. Un ID fuera de alcance devuelve 404; carecer del permiso devuelve 403 antes de consultar el registro. La creación usa `scope.new`, de modo que la organización se asigna en servidor. No permitas que un formulario cambie `organization_id`. Prueba siempre con dos organizaciones.

Las asociaciones `belongs_to` editables necesitan un recurso relacionado, por ejemplo `relation :category, resource: "categories"`, además de `fields/permit :category_id`. La gema verifica permiso de lectura, política y alcance del destino. Las opciones se consultan de 20 en 20, con búsqueda. Las relaciones polimórficas no tienen soporte declarado.

La página normal contiene 25 filas y admite hasta 100, con orden estable. Filtros y orden solo usan listas explícitas. Si tu modelo tiene `lock_version`, el formulario detecta ediciones y confirmaciones de borrado obsoletas con HTTP 409. Un borrado con dependientes se presenta como un error recuperable.

Consulta [precargas y coste de consultas](performance.md) si tus políticas acceden a asociaciones.
