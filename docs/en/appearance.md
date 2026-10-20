# Appearance and locale

The theme ports django-newadmin tokens: light canvas `#f8f9ff`, white surfaces, text `#0b1c30`; dark canvas `#11161d`, text `#eaf0f8`. It uses Segoe UI/system-ui typography and selected Bootstrap components compiled into the gem. No external fonts or CDNs are required.

```ruby
RailsNewadmin.configure do |config|
  config.site_title = "My administration"
  config.default_mode = :auto # :light, :dark
  config.default_locale = :en
  config.available_locales = [:es, :en]
end
```

Appearance cycles through auto/light/dark and persists locally. ES/EN uses a mount-scoped locale cookie and request-local `I18n.with_locale`. Translate model/attribute names through normal Rails I18n conventions; business values are not translated automatically.

Override `--newadmin-*` custom properties in a stylesheet loaded after the engine CSS. Editing compiled gem files makes upgrades difficult; prefer explicit tokens or view overrides. The visual layer uses `.newadmin-*` classes, but test navigation boundaries and overrides when a host has its own assets.

Labels, visible focus, error messages, table headings and mobile reflow are included. WCAG certification and compatibility with every assistive technology or browser are not claimed.
