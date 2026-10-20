# frozen_string_literal: true

module RailsNewadmin
  # Implement all four methods in a host application class. Instances are request-local.
  class HostAuthenticationAdapter
    METHODS = %i[current_user active? login_path logout_path].freeze

    def self.validate_contract!
      missing = METHODS.select do |name|
        next true unless public_method_defined?(name)
        method = instance_method(name)
        keyword = name == :active? ? :user : :controller
        method.owner == HostAuthenticationAdapter || method.parameters != [ [ :keyreq, keyword ] ]
      end
      raise ConfigurationError, "Host adapter must implement: #{missing.join(', ')}" if missing.any?
    end

    def current_user(controller:) = raise NotImplementedError
    def active?(user:) = raise NotImplementedError
    def login_path(controller:) = raise NotImplementedError
    def logout_path(controller:) = raise NotImplementedError
  end
end
