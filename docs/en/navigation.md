# Navigation and assets

The admin layout owns its local Turbo and Stimulus bundles. Your application keeps its own JavaScript setup. Moving between the two layouts performs a full document navigation; links and forms inside the admin continue to use Turbo. This boundary prevents the host and engine runtimes from running together.

## Link from your application

Use the mount proxy created by the installer, and explicitly request a full navigation:

```erb
<%= link_to "Administration", rails_newadmin.root_path,
      data: { turbo: false } %>
```

Do not hardcode `/admin` when you use another mount or deployment prefix. The engine's tracked assets also cause a reload when a plain Turbo link enters it from a different layout; keeping `data-turbo="false"` makes your intent explicit. Normal browser back/forward navigation remains available.

When adding a link back in an overridden admin view, use `main_app`:

```erb
<%= link_to "Back to site", main_app.root_path,
      data: { turbo: false } %>
```

The admin also intercepts Turbo visits leaving its mount and performs a full navigation. Host-mode logout already posts a CSRF-protected DELETE directly to the host endpoint and uses a full navigation. Do not replace it with a GET link. See [Authentication](authentication.md).

## Keep your existing JavaScript setup

For an **importmap** host, keep its import map, pins, Turbo and Stimulus entrypoint in the host layout:

```erb
<%= javascript_importmap_tags %>
```

For an **esbuild** host, keep its compiled application bundle in that layout:

```erb
<%= javascript_include_tag "application", defer: true,
      data: { turbo_track: "reload" } %>
```

Neither setup needs to import `rails_newadmin/application` or start the engine's Stimulus application. The engine loads its own namespaced assets. When overriding its layout, retain those assets, their `data-turbo-track="reload"` attributes, CSRF tags and mount metadata; do not add the host entrypoint or `javascript_importmap_tags` there. Copying the host layout into the admin can initialize Turbo twice.

The tested consumer recipes use importmap-rails 2.2.2 with local Turbo 8.0.23/Stimulus 3.2.2, and an esbuild host using the same versions. Both were checked in Chromium with Propshaft and Rails 8.0/8.1. This does not certify every JavaScript bundler, custom Turbo override or deployment topology. Rails explains [import maps and bundlers](https://guides.rubyonrails.org/working_with_javascript_in_rails.html); Turbo documents [tracked assets and navigation boundaries](https://turbo.hotwired.dev/handbook/drive).

## Another mount and a deployment prefix

Choose the engine mount during installation:

```sh
bin/rails generate rails_newadmin:install --path /control
```

If the whole application lives at `/portal`, its public admin URL is `/portal/control`. The mount remains `/control` in `config/routes.rb`: `/portal` belongs to the application's deployment, not to the engine mount. Your Rack server or proxy must pass `SCRIPT_NAME=/portal` and strip that prefix from `PATH_INFO`. Set the application's relative URL root consistently when precompiling and serving:

```sh
RAILS_RELATIVE_URL_ROOT=/portal RAILS_ENV=production bin/rails assets:precompile
RAILS_RELATIVE_URL_ROOT=/portal RAILS_ENV=production bin/rails server
```

The environment variable does not configure a proxy or mount the application by itself. Test the public URLs and serve compiled assets at `/portal/assets`. The verified recipe uses a Rack URL map for `/portal`; if your proxy instead strips paths, configure the equivalent Rack variables. Avoid duplicating `/portal` in the installer path or adapter routes. Use `controller.main_app.new_session_path` and `controller.main_app.session_path` in host adapters so they inherit the request prefix. Authentication paths must stay outside the admin mount; dot segments and encoded separators are rejected to prevent ambiguous redirects.

## Production and troubleshooting

The gem ships compiled assets; no Node process is needed to precompile its assets or serve the admin. The verified esbuild recipe builds the host bundle directly before Rails precompilation. Your application's bundler may still require Node during its build; for example, jsbundling-rails can run a JavaScript build as part of `assets:precompile`. Build host assets first, then run Rails precompilation. Do not remove the host's build step merely because the gem includes its own bundles.

Dashboard charts load only when a dashboard declares charts. Opening a list directly does not fetch ECharts. Navigating away disposes charts, resize observers and theme listeners; returning creates the current chart once. A theme-button click should advance one mode, and submitting one form should send one request.

For duplicate clicks or Turbo warnings, inspect overridden layouts and remove the extra entrypoint. For asset 404s, check Propshaft, precompilation and the deployment prefix before changing JavaScript. Keep the browser console and network panel open while testing host → admin → resource → back → host, including logout. Consult [Production](production.md) for HTTPS, cache storage and serving assets.
