class Article < ActiveRecord::Base
  belongs_to :organization
  belongs_to :category, optional: true
  validates :title, presence: true
  validates :status, inclusion: { in: %w[draft published archived] }
end
