class NavigationDashboard < RailsNewadmin::DashboardProvider
  requires "articles"

  def call
    { metrics: [], charts: [ { id: "status", title: "Article status", type: "bar",
      columns: [ "Status", "Count" ], rows: scope("articles").group(:status).count.map { |key, count| [ key.to_s, count ] } } ] }
  end
end
