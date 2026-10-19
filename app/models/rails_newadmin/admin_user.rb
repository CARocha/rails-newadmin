module RailsNewadmin
  class AdminUser < ApplicationRecord
    has_secure_password
    has_many :sessions, class_name: "RailsNewadmin::AdminSession", dependent: :destroy
    has_many :memberships, dependent: :destroy
    has_many :groups, through: :memberships
    normalizes :email_address, with: ->(email) { email.strip.downcase }
    validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, length: { minimum: 12 }, if: -> { new_record? || password.present? }
    validates :locale, inclusion: { in: %w[es en] }, allow_nil: true
    after_update :revoke_sessions, if: -> { saved_change_to_password_digest? || (saved_change_to_active? && !active?) }

    def administrative? = active? && staff?

    def has_permission?(resource_key, action)
      granted_permissions.where(resource_key: resource_key, action: action).exists?
    end

    def granted_permissions
      Permission.joins("INNER JOIN rails_newadmin_group_permissions ON rails_newadmin_group_permissions.permission_id = rails_newadmin_permissions.id")
        .joins("INNER JOIN rails_newadmin_memberships ON rails_newadmin_memberships.group_id = rails_newadmin_group_permissions.group_id")
        .where(rails_newadmin_memberships: { admin_user_id: id }, active: true)
    end

    private

    def revoke_sessions
      sessions.destroy_all
    end
  end
end
