class CategoryResource < RailsNewadmin::Resource
  model "Category"
  key "categories"
  columns :id, :name
  fields :name
  permit :name
  search :name
  policy "ArticleAdminPolicy"
end
