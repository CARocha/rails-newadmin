# Dashboards and charts

The default dashboard counts readable resources within policy scopes. Add a per-request provider for business metrics. Declare every source; missing access prevents provider execution.

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

The contract accepts up to 12 metrics and 8 bar/line charts, each with two columns (text/finite number) and at most 1,000 rows. Arbitrary JavaScript, HTML and ECharts options are not accepted. A provider is trusted developer code: use `scope` rather than global queries for user-visible data.

ECharts is local and loaded only when charts exist. SVG rendering includes an HTML table alternative; theme, resize and Turbo disconnect clean up instances. Tables remain useful without JavaScript. Ordinary lists do not download the chart bundle.
