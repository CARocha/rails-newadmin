class Category < ActiveRecord::Base
  has_many :articles, dependent: :restrict_with_exception
  belongs_to :organization
  validates :name, presence: true
end
