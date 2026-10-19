module RailsNewadmin
  class Permission < ApplicationRecord
    ACTIONS = %w[view create update destroy].freeze
    validates :resource_key, :action, presence: true
    validates :action, inclusion: { in: ACTIONS + ["manage_access"] }
    validates :action, uniqueness: { scope: :resource_key }

    def self.sync!(registry = RailsNewadmin.registry)
      transaction do
        keys = registry.map(&:resource_key)
        where.not(resource_key: keys + ["admin_access"]).update_all(active: false)
        keys.each do |key|
          ACTIONS.each { |action| find_or_initialize_by(resource_key: key, action: action).update!(active: true) }
        end
        find_or_initialize_by(resource_key: "admin_access", action: "manage_access").update!(active: true)
      end
    end
  end
end
