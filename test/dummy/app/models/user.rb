class User < ActiveRecord::Base
  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :organization
  normalizes :email_address, with: ->(email) { email.strip.downcase }
end
