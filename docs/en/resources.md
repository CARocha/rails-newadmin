# Resources and policies

Declare resources in `app/admin/resources` and policies in `app/policies`. Class-name strings support reloading. Models are never automatically exposed.

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

Presentation, search, filters and writes use separate allowlists. Writes intersect `permit`, `fields` and policy attributes. Never expose password digests, secrets or tokens. Columns must be actual Active Record attributes; computed columns and composite primary keys are outside this alpha contract.

For shared data visible to all authorized staff, use this explicit single-site policy:

```ruby
class ArticleAdminPolicy < RailsNewadmin::Policy
  def allowed?(actor:, action:, record: nil) = true
  def scope(actor:, relation:) = relation.all
  def permitted_attributes(actor:, action:, record: nil) = resource.permitted_fields
end
```

Equivalent generator: `Article --single-site --permit title body status`. This opens scope to the entire table; group grants are still required. The base policy returns false, `none` and no writable fields.

For organization-separated data, retain the closed generator output and supply a scope such as this. `AdminProfile` and `organization_id` belong to your application, not the gem:

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

Scopes apply to superusers too. Out-of-scope IDs return 404; missing grants return 403 before a record lookup. Creation uses `scope.new` to assign the organization on the server. Do not permit clients to change `organization_id`. Test with two organizations.

Writable `belongs_to` fields require a related resource declaration, for example `relation :category, resource: "categories"`, plus `fields/permit :category_id`. Target read grants, policy and scope are checked. Options are searched and paginated in batches of 20. Polymorphic relations are outside the supported contract.

Default page size is 25, maximum 100, with stable ordering. Search/filter/sort fields are explicitly allowlisted. A model with `lock_version` detects stale edits and delete confirmations with HTTP 409. Dependent-record deletion restrictions are recoverable errors.
