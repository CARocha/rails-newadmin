class ArticleAdminPolicy < RailsNewadmin::Policy
  def allowed?(actor:, action:, record: nil) = true

  def scope(actor:, relation:)
    id = AdminProfile.find_by(admin_user_id: actor.id)&.organization_id
    id ? relation.where(organization_id: id) : relation.none
  end

  def permitted_attributes(actor:, action:, record: nil)
    resource.permitted_fields
  end
end
