class Submission < ActiveRecord::Base
  attr_accessible :assignment_id, :submission, :submitted, :user_id, :instructor_approved

  mount_uploader :submission, SubmissionUploader

  # Relationships
  belongs_to :user
  belongs_to :assignment
  has_many :evaluations

  # Validations
  validates_presence_of :assignment_id
  validates_presence_of :user_id
end
