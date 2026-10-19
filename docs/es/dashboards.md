# Dashboards y gráficos

El dashboard inicial cuenta los recursos que puedes leer, siempre dentro de su alcance. Añade un proveedor por petición para métricas de negocio. Declara todas las fuentes; si falta permiso, no se ejecuta el proveedor.

```ruby
class EditorialDashboard < RailsNewadmin::DashboardProvider
  requires "articles"
  def call
    rows = scope("articles").group(:status).count.map { |status, count| [status, count] }
    { metrics: [], charts: [{ id: "article-status", title: "Article status",
      type: "bar", columns: ["Status", "Count"], rows: rows }] }
  end
end
# config/initializers/rails_newadmin.rb
RailsNewadmin.configure { |config| config.dashboard_provider = "EditorialDashboard" }
```

El contrato acepta hasta 12 métricas y 8 gráficos bar/line, cada uno con dos columnas (texto/número finito) y hasta 1 000 filas. No acepta JavaScript, HTML ni opciones ECharts arbitrarias. El proveedor es código de confianza del desarrollador: debe usar `scope` y no consultas globales para los datos del usuario.

ECharts se sirve localmente y se carga solo cuando hay gráficos. El render es SVG, con una tabla HTML alternativa; tema, resize y desconexión Turbo limpian las instancias. La tabla sigue siendo útil sin JavaScript. No se descarga un bundle de gráficos en una lista ordinaria.
