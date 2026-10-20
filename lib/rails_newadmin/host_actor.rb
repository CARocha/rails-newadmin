# frozen_string_literal: true

module RailsNewadmin
  # Policies use actor.user for application-specific fields and tenant relationships.
  class HostActor
    attr_reader :user, :identity

    def initialize(user, identity)
      @user, @identity = user, identity
    end

    delegate :id, to: :user
    delegate :administrative?, :superuser?, :locale, :granted_permissions, :has_permission?, to: :identity
  end
end
