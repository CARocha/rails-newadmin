module RailsNewadmin
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception
    layout "rails_newadmin/application"
    before_action :require_admin
    around_action :with_admin_locale
    before_action :secure_admin_response
    helper_method :current_actor, :admin_config

    private

    def admin_config = RailsNewadmin.configuration

    def current_admin_session
      return @current_admin_session if defined?(@current_admin_session)
      @current_admin_session = AdminSession.resume(cookies.encrypted[:rails_newadmin_session])
    end

    def current_actor = current_admin_session&.admin_user

    def require_admin
      redirect_to new_session_path unless current_actor
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
