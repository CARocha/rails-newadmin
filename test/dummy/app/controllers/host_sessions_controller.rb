# Existing application login, using Rails authentication-generator primitives.
class HostSessionsController < ActionController::Base
  protect_from_forgery with: :exception

  def new
    render inline: '<%= csrf_meta_tags %><%= form_with url: host_session_path do |f| %><%= f.email_field :email_address %><%= f.password_field :password %><%= f.submit "Sign in" %><% end %>'
  end

  def create
    user = User.authenticate_by(params.permit(:email_address, :password).to_h.symbolize_keys)
    return head :unauthorized unless user&.active?
    reset_session
    record = user.sessions.create!(ip_address: request.remote_ip, user_agent: request.user_agent)
    cookies.signed[:session_id] = { value: record.id, httponly: true, same_site: :lax, secure: request.ssl? }
    redirect_to "/admin", status: :see_other
  end

  def destroy
    Session.find_by(id: cookies.signed[:session_id])&.destroy!
    cookies.delete(:session_id)
    reset_session
    redirect_to new_host_session_path, status: :see_other
  end
end
