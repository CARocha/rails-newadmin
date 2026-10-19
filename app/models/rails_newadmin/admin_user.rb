module RailsNewadmin
  class AdminUser < ApplicationRecord
    has_secure_password
    has_many :sessions, class_name: "RailsNewadmin::AdminSession", dependent: :destroy
    normalizes :email_address, with: ->(email) { email.strip.downcase }
    validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
    validates :password, length: { minimum: 12 }, if: -> { new_record? || password.present? }
    validates :locale, inclusion: { in: %w[es en] }, allow_nil: true
    after_update :revoke_sessions, if: -> { saved_change_to_password_digest? || (saved_change_to_active? && !active?) }

    def administrative? = active? && staff?

    private

    def revoke_sessions
      sessions.destroy_all
    end
  end
end
