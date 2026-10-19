module RailsNewadmin
  class Group < ApplicationRecord
    has_many :memberships, dependent: :destroy
    has_many :admin_users, through: :memberships
    has_many :group_permissions, dependent: :destroy
    has_many :permissions, through: :group_permissions
    validates :name, presence: true, uniqueness: true
  end
end
