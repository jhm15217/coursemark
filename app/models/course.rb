class Course < ActiveRecord::Base
  attr_accessible :name

  # Relationships
  has_many :registrations
  has_many :assignments
  has_many :users, :through => :registrations

end
