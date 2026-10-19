class AdminProfile < ActiveRecord::Base
  belongs_to :admin_user, class_name: "RailsNewadmin::AdminUser"
  belongs_to :organization
end
