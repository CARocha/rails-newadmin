class EditorialDashboard < RailsNewadmin::DashboardProvider
  requires "articles", "categories"

  def call
    rows = scope("articles").group(:status).count.map { |status, count| [ status, count ] }
    {
      metrics: [ { label: I18n.locale == :es ? "Publicados" : "Published", value: scope("articles").where(status: "published").count } ],
      charts: [ { id: "articles-status", title: I18n.locale == :es ? "Artículos por estado" : "Articles by status",
        type: "bar", columns: [ I18n.locale == :es ? "Estado" : "Status", I18n.locale == :es ? "Artículos" : "Articles" ], rows: rows } ]
    }
  end
end
