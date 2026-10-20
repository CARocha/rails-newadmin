module RailsNewadmin
  # Authorization metadata only. Credentials and sessions always belong to the host.
  class ActorIdentity < ApplicationRecord
    has_many :actor_memberships, dependent: :destroy
    has_many :groups, through: :actor_memberships
    validates :actor_type, :actor_id, presence: true, length: { maximum: 255 }
    validates :actor_id, uniqueness: { scope: :actor_type }
    validates :locale, inclusion: { in: %w[es en] }, allow_nil: true

    def self.key_for(user)
      unless user.is_a?(ActiveRecord::Base) && user.persisted? && !user.destroyed? && !user.class.composite_primary_key?
        raise ConfigurationError, "Host adapter must return a persisted ActiveRecord model with a scalar primary key"
      end
      { actor_type: user.class.base_class.name, actor_id: user.id.to_s }
    end

    def self.for_user(user) = find_by(key_for(user))
    def administrative? = active? && staff?

    def granted_permissions
      Permission.joins("INNER JOIN rails_newadmin_group_permissions ON rails_newadmin_group_permissions.permission_id = rails_newadmin_permissions.id")
        .joins("INNER JOIN rails_newadmin_actor_memberships ON rails_newadmin_actor_memberships.group_id = rails_newadmin_group_permissions.group_id")
        .where(rails_newadmin_actor_memberships: { actor_identity_id: id }, active: true)
    end

    def has_permission?(resource_key, action)
      granted_permissions.where(resource_key: resource_key, action: action).exists?
    end
  end
end
