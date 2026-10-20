# For the unmodified Rails 8 authentication generator. Adapt to your session rules.
class NewadminHostAdapter < RailsNewadmin::HostAuthenticationAdapter
  def current_user(controller:)
    ::Session.find_by(id: controller.request.cookie_jar.signed[:session_id])&.user
  end

  # The generated User has no active column. Add your own suspension/expiry checks.
  def active?(user:) = user.persisted?
  def login_path(controller:) = controller.main_app.new_session_path
  def logout_path(controller:) = controller.main_app.session_path
end
