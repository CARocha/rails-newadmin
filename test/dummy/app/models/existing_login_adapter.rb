class ExistingLoginAdapter < RailsNewadmin::HostAuthenticationAdapter
  def current_user(controller:)
    Session.find_by(id: controller.request.cookie_jar.signed[:session_id])&.user
  end

  def active?(user:) = user.active?
  def login_path(controller:) = controller.main_app.new_host_session_path
  def logout_path(controller:) = controller.main_app.host_session_path
end
