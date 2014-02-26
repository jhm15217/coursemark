class Registration < ActiveRecord::Base
  attr_accessible :active, :course_id, :instructor, :user_id

  # Relationships
  belongs_to :user
  belongs_to :course
  
end