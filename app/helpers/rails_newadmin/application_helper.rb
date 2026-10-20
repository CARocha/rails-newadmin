module RailsNewadmin
  module ApplicationHelper
    def admin_page_title
      section = case controller_name
      when "resources" then resource_label
      when "admin_users" then t("rails_newadmin.access.users")
      when "groups" then t("rails_newadmin.access.groups")
      when "sessions" then t("rails_newadmin.auth.title")
      when "passwords" then t("rails_newadmin.recovery.title")
      else t("rails_newadmin.dashboard.title")
      end
      action = { "new" => "new", "create" => "new", "edit" => "edit", "update" => "edit", "delete" => "delete", "destroy" => "delete", "show" => "view" }[action_name] if %w[resources admin_users groups].include?(controller_name)
      [ action && t("rails_newadmin.crud.#{action}"), section, admin_config.site_title ].compact.join(" · ")
    end

    def field_error_attributes(record, field, scope:)
      invalid = record.errors[field].any?
      { aria: { invalid: invalid, describedby: invalid ? [ scope, field, "error" ].compact.join("_") : nil } }
    end
  end
end
