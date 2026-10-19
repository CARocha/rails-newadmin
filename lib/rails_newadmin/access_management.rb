# frozen_string_literal: true
module RailsNewadmin
  class AccessManagement
    class LastSuperuser < StandardError; end

    def initialize(actor, request_id: nil)
      @actor, @request_id = actor, request_id
      raise AccessDenied unless actor&.administrative? && (actor.superuser? || actor.has_permission?("admin_access", "manage_access"))
    end

    def update_user!(user, attributes)
      attributes = attributes.to_h.symbolize_keys
      raise AccessDenied if !@actor.superuser? && (user.superuser? || attributes.key?(:superuser))
      allowed = [:email_address, :password, :password_confirmation, :active, :staff, :superuser, :locale, :group_ids]
      raise ArgumentError, "unknown account fields" if (attributes.keys - allowed).any?
      AdminUser.transaction do
        # Stable lock ordering serializes concurrent attempts to remove the final owner.
        AdminUser.where(superuser: true).order(:id).lock.load
        user.lock! if user.persisted?
        user.assign_attributes(attributes.except(:group_ids))
        if user.persisted? && (!user.active? || !user.staff? || !user.superuser?) && AdminUser.where(active: true, staff: true, superuser: true).where.not(id: user.id).none?
          raise LastSuperuser, "At least one active superuser must remain"
        end
        user.save!
        if attributes.key?(:group_ids)
          ids = Array(attributes[:group_ids]).reject(&:blank?).map(&:to_s).uniq
          raise AccessDenied unless Group.where(id: ids).count == ids.size
          user.group_ids = ids
        end
        AuditEvent.record!(actor: @actor, resource: "admin_users", action: :update, record: user, request_id: @request_id)
      end
      user
    end

    def save_group!(group, attributes)
      values = attributes.to_h.symbolize_keys
      ids = Array(values[:permission_ids]).reject(&:blank?).map(&:to_s).uniq
      permissions = Permission.where(id: ids, active: true)
      if permissions.count != ids.size
        group.errors.add(:base, I18n.t("rails_newadmin.access.invalid_permissions"))
        raise ActiveRecord::RecordInvalid, group
      end
      Group.transaction do
        group.update!(name: values[:name])
        group.permission_ids = ids
        AuditEvent.record!(actor: @actor, resource: "admin_groups", action: :update, record: group, request_id: @request_id)
      end
      group
    end
  end
end
