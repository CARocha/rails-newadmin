module RailsNewadmin
  class SessionsController < ApplicationController
    prepend_before_action :require_builtin_authentication
    skip_before_action :require_admin, only: [ :new, :create ]
    rate_limit to: 10, within: 3.minutes, only: :create, store: RateLimitStore.new,
      with: -> { render :new, status: :too_many_requests }

    def new; end

    def create
      email = params[:email_address].to_s.strip.downcase
      user = AdminUser.authenticate_by(email_address: email, password: params[:password].to_s)
      if user&.administrative?
        current_admin_session&.destroy!
        reset_session
        token = AdminSession.start!(user)
        cookies.encrypted[:rails_newadmin_session] = {
          value: token, httponly: true, same_site: :lax, secure: request.ssl?,
          expires: admin_config.session_lifetime.from_now, path: request.script_name.presence || "/"
        }
        redirect_to root_path, status: :see_other
      else
        flash.now[:alert] = t("rails_newadmin.auth.invalid")
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      current_admin_session.destroy!
      reset_session
      cookies.delete(:rails_newadmin_session, path: request.script_name.presence || "/")
      redirect_to new_session_path, status: :see_other
    end
  end
end
