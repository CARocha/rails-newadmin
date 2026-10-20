# frozen_string_literal: true

module RailsNewadmin
  class HostAuthentication
    def self.adapter_class
      klass = RailsNewadmin.configuration.authentication_adapter.safe_constantize
      unless klass.is_a?(Class) && klass < HostAuthenticationAdapter
        raise ConfigurationError, "authentication_adapter must name a HostAuthenticationAdapter subclass"
      end
      klass.validate_contract!
      klass
    end

    def initialize(controller)
      @controller = controller
      @adapter = self.class.adapter_class.new
    end

    def actor
      user = @adapter.current_user(controller: @controller)
      return unless user
      identity = ActorIdentity.for_user(user)
      raise AccessDenied unless @adapter.active?(user: user) == true && identity&.administrative?
      HostActor.new(user, identity)
    end

    def login_path = local_host_path(@adapter.login_path(controller: @controller))
    def logout_path = local_host_path(@adapter.logout_path(controller: @controller))

    private

    def local_host_path(path)
      # Never accept an origin, scheme-relative URL, browser-normalized backslash or engine loop.
      unless path.is_a?(String) && path.start_with?("/") && !path.start_with?("//") && !/[\\\x00-\x20\x7f]/.match?(path)
        raise ConfigurationError, "Host authentication paths must be local absolute paths"
      end
      pathname = URI.parse(path).path
      decoded = URI::RFC2396_PARSER.unescape(pathname)
      if decoded.split("/").any? { |part| part == "." || part == ".." } || /%(?:2f|5c|25)/i.match?(pathname)
        raise ConfigurationError, "Host authentication paths cannot contain dot segments or encoded separators"
      end
      mount = @controller.request.script_name
      if mount.present? && (pathname == mount || pathname.start_with?("#{mount}/"))
        raise ConfigurationError, "Host authentication paths must be outside the admin mount"
      end
      path
    rescue URI::InvalidURIError
      raise ConfigurationError, "Invalid host authentication path"
    end
  end
end
