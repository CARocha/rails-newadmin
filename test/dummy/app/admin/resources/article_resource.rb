class ArticleResource < RailsNewadmin::Resource
  model "Article"
  key "articles"
  columns :id, :title, :status, :updated_at
  fields :title, :body, :status, :category_id
  permit :title, :body, :status, :category_id
  search :title
  filters :status
  policy "ArticleAdminPolicy"
  relation :category, resource: "categories"
end
