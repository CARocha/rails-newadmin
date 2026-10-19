module RailsNewadmin
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    def self.table_name_prefix = "rails_newadmin_"
  end
end
