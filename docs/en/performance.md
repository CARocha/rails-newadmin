# Queries and performance

Lists use 25 records per page and cap `per_page` at 100. Autocomplete returns up to 20 options per request. When editing, the selector may add the authorized current value if it is outside the first 20 options; this preserves the selection without changing the search endpoint limit.

Policies and scopes still apply to every query. Do not put permissions, identities or per-user results in a shared cache without a strategy that preserves revocation and tenant isolation.

## Avoiding per-row queries

List columns read database attributes. A policy that accesses associations for each record can introduce N+1 queries. Declare only the associations it actually needs:

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

Also register the `categories` resource with its own policy, as described in the [resource guide](resources.md).

This DSL's `includes` uses Active Record `preload` for the bounded page; it does not automatically load every association. Preloads do not authorize resources or replace `scope` or `allowed?`. Avoid extra queries inside your policy: a preload cannot eliminate independent calls such as `Category.find(record.category_id)`.

For nested associations, declare the Active Record preload in your scope, for example `relation.where(organization_id: organization_id).preload(category: :organization)`. The `includes` DSL accepts simple association names.

Count queries for the whole journey, including authorization, the layout and per-record policies. Comparing 25-row and 50-row pages helps detect per-row growth. Count SQL query-cache hits too, as they can hide an N+1 pattern. See the [Rails preloading guide](https://guides.rubyonrails.org/active_record_querying.html#preload).

## Observing collection cost

Subscribe to the local `query.rails_newadmin` event from an initializer:

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

| Field | Meaning |
|---|---|
| `resource_key` | Resource being queried; for relationships, the target resource |
| `operation` | `list` or `options` |
| `page`, `per_page` | Normalized, bounded pagination |
| `request_id` | Request correlation |
| `success` | The instrumented read completed successfully |

List duration covers loading the page, its preloads and its exact count. Options duration covers loading choices and, when editing, looking up the current selection. It excludes earlier authorization/scope decisions, rendering and any per-row policy queries outside collection loading. Measure the complete request through Rails instrumentation or your APM for total server time.

The event is emitted after collection authorization; denied collections do not emit it. Read failures preserve the original error and publish `success: false`, without adding exception messages or objects, SQL, records, filters, passwords or tokens. No remote telemetry or logger is installed automatically. Keep subscribers fast and avoid synchronous network operations; group metrics by resource/operation rather than `request_id`. Other Rails events and logs have their own data and configuration. See [ActiveSupport::Notifications](https://api.rubyonrails.org/v8.1.0/classes/ActiveSupport/Notifications.html).

## Host indexes, counts and limits

Counts are exact and may be expensive with large tables or complex scopes. Pagination uses offset; deep pages can require scanning many rows. Sorting by another allowed column adds the primary key as a stable tie-breaker.

Inspect your application's real queries with `EXPLAIN (ANALYZE, BUFFERS)` before adding indexes. Filtering by tenant and ordering by ID may justify a composite index, depending on your data. Text search uses contains matching; a conventional B-tree index may not satisfy it. Own indexes and search strategy in your application; the gem does not automatically modify business tables.

Configure and test database pool limits and timeouts for your deployment. The gem does not set a global `statement_timeout` or cancel queries using its own deadline. Host limits may affect other processes sharing the connection or role.

Measure latency in production mode with representative data and recorded cache/concurrency settings. Query budgets and bounded result sizes help prevent regressions; they do not guarantee universal latency or replace load tests in your application. Charts remain in a separate bundle that pages without charts do not request.
