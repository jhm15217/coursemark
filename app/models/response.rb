class Response < ActiveRecord::Base
  attr_accessible :evaluation_id, :instructor_response, :peer_review, :question_id, :scale_id, :student_response

  # Relationships
  belongs_to :question
  belongs_to :scale
  belongs_to :evaluation

  # Validations
  validates_presence_of :question_id, :scale_id, :evaluation_id

end