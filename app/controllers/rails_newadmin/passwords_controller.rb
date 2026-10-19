module RailsNewadmin
  class PasswordsController < ApplicationController
    skip_before_action :require_admin
    before_action :load_user, only: [:edit, :update]
    rate_limit to: 10, within: 3.minutes, only: :create, store: RateLimitStore.new,
      with: -> { render :new, status: :too_many_requests }

    def new; end
    def edit; end

    def create
      user = AdminUser.find_by(email_address: params[:email_address].to_s.strip.downcase, active: true, staff: true)
      if user
        options = Rails.application.config.action_mailer.default_url_options.to_h.symbolize_keys
        raise ConfigurationError, "Action Mailer default_url_options.host is required for recovery" unless options[:host].present?
        options[:protocol] = "https" if Rails.env.production?
        url = Engine.routes.url_helpers.edit_password_url(**options, script_name: request.script_name, token: user.password_reset_token)
        PasswordsMailer.with(user: user, reset_url: url, locale: I18n.locale).reset.deliver_later
      end
      redirect_to new_session_path, status: :see_other, notice: t("rails_newadmin.recovery.sent")
    end

    def update
      if @user.update(params.permit(:password, :password_confirmation))
        cookies.delete(:rails_newadmin_session, path: request.script_name.presence || "/")
        redirect_to new_session_path, status: :see_other, notice: t("rails_newadmin.recovery.updated")
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def load_user
      @user = AdminUser.find_by_password_reset_token!(params[:token].to_s)
      raise ActiveSupport::MessageVerifier::InvalidSignature unless @user.administrative?
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: t("rails_newadmin.recovery.invalid")
    end

    def secure_admin_response
      super
      response.headers["Referrer-Policy"] = "no-referrer"
    end
  end
end
