module RailsNewadmin
  class Membership < ApplicationRecord
    belongs_to :admin_user
    belongs_to :group
    validates :admin_user_id, uniqueness: { scope: :group_id }
  end
end
