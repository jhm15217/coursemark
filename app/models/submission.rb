class Submission < ActiveRecord::Base
  attr_accessible :assignment_id, :submission, :submitted, :user_id

  mount_uploader :submission, SubmissionUploader

  # Relationships
  belongs_to :user
  belongs_to :assignment
  has_many :evaluations
  
end