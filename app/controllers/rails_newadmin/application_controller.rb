module RailsNewadmin
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    layout "rails_newadmin/application"
    before_action :secure_admin_response
    before_action :require_admin
    around_action :with_admin_locale
    helper_method :current_actor, :admin_config, :host_authentication?, :admin_logout_path
    helper_method :can_manage_access?, :resource_access
    rescue_from RailsNewadmin::AccessDenied, with: -> { render_access_denied }

    private

    # Do not resolve the actor again: host authentication may itself have denied access.
    def render_access_denied
      return head(:forbidden) unless request.format.html?
      requested = params[:locale].presence || cookies[:rails_newadmin_locale].presence || @current_actor&.locale || admin_config.default_locale
      locale = requested.to_s.to_sym
      locale = admin_config.default_locale unless admin_config.available_locales.include?(locale)
      I18n.with_locale(locale) do
        render "rails_newadmin/errors/forbidden", layout: "rails_newadmin/error", status: :forbidden
      end
    end

    def admin_config = RailsNewadmin.configuration

    def current_admin_session
      return @current_admin_session if defined?(@current_admin_session)
      @current_admin_session = AdminSession.resume(cookies.encrypted[:rails_newadmin_session])
    end

    def host_authentication? = admin_config.authentication == :host
    def host_authentication = @host_authentication ||= HostAuthentication.new(self)
    def admin_logout_path = host_authentication? ? host_authentication.logout_path : session_path

    def current_actor
      return @current_actor if defined?(@current_actor)
      @current_actor = host_authentication? ? host_authentication.actor : current_admin_session&.admin_user
    end

    def require_builtin_authentication
      head :not_found if host_authentication?
    end
    def can_manage_access? = current_actor&.administrative? && (current_actor.superuser? || current_actor.has_permission?("admin_access", "manage_access"))

    def resource_access(resource)
      @request_permissions ||= current_actor.superuser? ? [] : current_actor.granted_permissions.pluck(:resource_key, :action).freeze
      Access.new(current_actor, resource, permissions: @request_permissions)
    end

    def require_admin
      redirect_to(host_authentication? ? host_authentication.login_path : new_session_path) unless current_actor
    end

    def with_admin_locale(&block)
      requested = params[:locale].presence || cookies[:rails_newadmin_locale].presence || current_actor&.locale || admin_config.default_locale
      locale = requested.to_s.to_sym
      locale = admin_config.default_locale unless admin_config.available_locales.include?(locale)
      cookies[:rails_newadmin_locale] = { value: locale, same_site: :lax, path: request.script_name.presence || "/" } if params[:locale].present?
      I18n.with_locale(locale, &block)
    end

    def secure_admin_response
      response.headers["Cache-Control"] = "no-store"
      response.headers["X-Frame-Options"] = "SAMEORIGIN"
      response.headers["X-Content-Type-Options"] = "nosniff"
      response.headers["Referrer-Policy"] = "same-origin"
    end
  end
end
