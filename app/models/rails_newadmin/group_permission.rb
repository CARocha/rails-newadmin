module RailsNewadmin
  class GroupPermission < ApplicationRecord
    belongs_to :group
    belongs_to :permission
    validates :group_id, uniqueness: { scope: :permission_id }
  end
end
