class Category < ActiveRecord::Base
  belongs_to :organization
  validates :name, presence: true
end
