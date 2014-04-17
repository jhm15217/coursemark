class Response < ActiveRecord::Base
  attr_accessible :evaluation_id, :instructor_response, :peer_review, :question_id, :scale_id, :student_response

  # Relationships
  belongs_to :question
  belongs_to :scale
  belongs_to :evaluation

  # Validations
  validates_presence_of :question_id, :evaluation_id
  validate :met_deadline, :if => :peer_review_changed?, :if => :scale_id_changed?

  validate :required_response

  def required_response
    if self.peer_review.blank? && self.question.written_response_required
      errors.add(:peer_review, "response required")
    end
  end

  def is_complete?
    if self.question.written_response_required
    	if !self.scale_id.blank? && !self.peer_review.blank? then 
    		return true
    	else 
    		return false
    	end
    else
      if !self.scale_id.blank? then 
        return true
      else 
        return false
      end
    end
  end 

  private
  def met_deadline
    if Time.now > self.evaluation.submission.assignment.review_due
      errors.add(:submission, "Deadline for evaluations has passed.")
    end 
  end

end
