class Assignment < ActiveRecord::Base
  attr_accessible :course_id, :draft, :review_due, :reviews_required, :submission_due, :name

  # Relationships
  belongs_to :course
  has_many :submissions
  has_many :questions
  
end