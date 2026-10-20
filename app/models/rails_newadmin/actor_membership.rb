module RailsNewadmin
  class ActorMembership < ApplicationRecord
    belongs_to :actor_identity
    belongs_to :group
    validates :actor_identity_id, uniqueness: { scope: :group_id }
  end
end
