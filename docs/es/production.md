# Producción

Usa HTTPS, `SECRET_KEY_BASE` seguro, backups y proxies de confianza. El limitador debe usar un backend compartido con incremento atómico. MemoryStore, FileStore y NullStore se rechazan en producción; si un incremento falla, el acceso falla cerrado. Un backend personalizado debe cumplir el mismo contrato, no solo tener un método con ese nombre.

```ruby
# Gemfile: Redis is one supported example chosen by the host.
gem "redis", "~> 5.0"
# config/environments/production.rb
config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL") }
config.action_mailer.default_url_options = { host: "admin.example.com", protocol: "https" }
config.action_mailer.default_options = { from: "no-reply@example.com" }
# config/initializers/rails_newadmin.rb
RailsNewadmin.configure { |config| config.rate_limit_store = Rails.cache }
```

Configura también transporte de correo y una cola durable de Active Job; la prueba usa entregas ficticias y no certifica tu SMTP. Redacta tokens/query strings en logs del proxy. Publica assets mediante `RAILS_ENV=production bin/rails assets:precompile` y sirve `public/assets` con el servidor/CDN de tu aplicación. Los bundles ya están compilados y no hace falta Node.

La navegación entre los layouts del host y del engine se verifica con importmap y esbuild, incluido montaje alternativo y prefijo. Sigue [Navegación y assets](navigation.md) para configurar los enlaces y conservar una sola instancia de Turbo.

No cambies el rango de Rails a 8.2/9 sin ejecutar la matriz. Ruby 3.4 es el mínimo; Ruby futuro no se considera certificado solo porque satisfaga el gemspec. Esta alfa fue ensayada con Ruby 3.4.8.
