class Response < ActiveRecord::Base
  attr_accessible :evaluation_id, :instructor_response, :peer_review, :question_id, :scale_id, :student_response

  # Relationships
  belongs_to :question
  belongs_to :scale
  belongs_to :evaluation

  # Validations
  validates_presence_of :question_id, :evaluation_id
  validate :met_deadline, :if => :peer_review_changed?, :if => :scale_id_changed?
  validate :response_allowed, :if => :student_response_changed?

  def is_complete?
    if self.question && self.question.written_response_required
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

  def self.check
    all.each do |r|
      unless (!r.evaluation_id or Evaluation.where(id: r.evaluation_id)) and (!r.scale_id or Scale.where(id: r.scale_id)) and
          (!r.question_id or Question.where(id: r.question_id))
        puts 'Error: Bad Registration: ' + r.inspect
        r.destroy
      end
    end
  end


  private
  def met_deadline
    if Time.zone.now > self.evaluation.submission.assignment.review_due
      errors.add(:submission, "Deadline for evaluations has passed.")
    end 
  end

  def response_allowed
    if self.evaluation.submission.instructor_approved 
      errors.add(:student_response, "The grade has already been approved by an instructor.")
    end
  end

end
