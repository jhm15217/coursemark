class Submission < ActiveRecord::Base
  attr_accessible :assignment_id, :submission, :submitted, :user_id, :instructor_approved

	after_save :create_and_save_evaluations

  mount_uploader :submission, SubmissionUploader

  # Relationships
  belongs_to :user
  belongs_to :assignment
  has_many :evaluations, dependent: :destroy

  # Validations
  validates_presence_of :assignment_id
  validates_presence_of :user_id

  private 
  def create_and_save_evaluations
  	if self.evaluations.length != self.assignment.reviews_required
	  	self.evaluations.delete_all
	  	courseStudents = self.assignment.course.get_students.without_user(self.user)
	  	evaluations = self.assignment.evaluations
	  	evaluationCounts = Hash.new
	  	courseStudents.map { |student| 
	  		evaluationCounts[student.id] = evaluations.forUser(student).count		
	  	}
	  	reviewThreshold = evaluationCounts.values.min
	  	evaluationsLeft = self.assignment.reviews_required
	  	evaluatorPool = []
	  	begin
	  		evaluatorPool.concat(courseStudents.select { |student|
	  			evaluationCounts[student.id] == reviewThreshold
	  		})
	  		evaluatorPool.shuffle!
	  		while evaluatorPool.length > 0 && evaluationsLeft > 0
	  			evaluator = evaluatorPool.pop
	  			evaluation = Evaluation.new
					evaluation.submission_id = self.id
					evaluation.user_id = evaluator.id
					evaluation.save
					evaluationsLeft -= 1
	  		end	
	 			reviewThreshold += 1
	  	end while evaluationsLeft > 0
	  end
  end
end
