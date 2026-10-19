require "digest"
require "securerandom"

module RailsNewadmin
  class AdminSession < ApplicationRecord
    belongs_to :admin_user
    validates :token_digest, presence: true, uniqueness: true

    def self.start!(user)
      raise ArgumentError, "inactive administrator" unless user.administrative?
      token = SecureRandom.urlsafe_base64(32)
      create!(admin_user: user, token_digest: Digest::SHA256.hexdigest(token),
        last_seen_at: Time.current, expires_at: Time.current + RailsNewadmin.configuration.session_lifetime)
      token
    end

    def self.resume(token)
      return unless token.is_a?(String) && token.bytesize.between?(40, 128)
      record = includes(:admin_user).find_by(token_digest: Digest::SHA256.hexdigest(token))
      return unless record && record.admin_user.administrative? && record.expires_at > Time.current
      return if record.last_seen_at < Time.current - RailsNewadmin.configuration.session_idle_timeout
      record.update!(last_seen_at: Time.current) if record.last_seen_at < 1.minute.ago
      record
    end
  end
end
