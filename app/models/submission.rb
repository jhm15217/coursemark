class Submission < ActiveRecord::Base
  attr_accessible :assignment_id, :submission, :user_id, :instructor_approved
  after_save :create_and_save_evaluations
  mount_uploader :submission, SubmissionUploader

  # Relationships
  belongs_to :user
  belongs_to :assignment
  has_many :evaluations, dependent: :destroy
  has_many :responses, :through => :evaluations

  # Validations
  validates_presence_of :assignment_id
  validates_presence_of :user_id
  validate :met_deadline, :on => :create

  def completed_responses
  	completed = []
  	self.responses.each do |response|
  		if response.is_complete?
  			completed << response
  		end
  	end
  	return completed
  end

  # evaluations assigned to the user who submitted this submission
  def evaluations_assigned
  	self.assignment.evaluations.forUser(self.user)
  end

  # evaluations completed to the user who submitted this submission
  def evaluations_completed
  	self.assignment.evaluations.forUser(self.user).select {|evaluation| evaluation.is_complete?}
  end

  # evaluations for this submission that were incomplete
  def evaluations_incomplete_for_submission
  	self.evaluations.select {|evaluation| not evaluation.is_complete?}
  end

  def raw
  	# Get only completed responses
  	responses = self.completed_responses
  	if responses.length > 0
			questions = Hash.new
			for response in responses
				question = questions[response.question_id] 
				if question
					question[:responses] += 1
					question[:total] += response.scale.value
				else
					question = Hash.new
					question[:responses] = 1
					question[:total] = response.scale.value
					question[:weight] = response.question.question_weight
					question[:max] = response.question.scales.maximum(:value)
					questions[response.question_id]  = question
				end 
			end
			
			totalQuestionWeight = questions.map{|k, v| v[:weight]}.reduce(:+)

			# if the total points of questions responded to doesn't equal
			# the number of points in the assignment, not all questions were
			# answered and the grade will be wrong
			if totalQuestionWeight != self.assignment.totalPoints
				nil
			end

			questions.map{ |k, v|
				(v[:total].fdiv(v[:responses] * v[:max])) * v[:weight]
			}.reduce(:+)
		else
			nil
		end
  end

  def percentage
  	grade = self.raw
  	if grade
  		grade.fdiv(self.assignment.totalPoints) * 100
  	end
  end

  #private

  def met_deadline
  	if Time.now > self.assignment.submission_due
      errors.add(:submission, "Deadline for assignment submission has passed.")
    end	
  end

  def create_and_save_evaluations
  	# only run if the number of evaluations isn't the number required
  	if self.evaluations.length != self.assignment.reviews_required
	  	self.evaluations.delete_all
	  	courseStudents = self.assignment.course.get_students.without_user(self.user)
	  	evaluations = self.assignment.evaluations
	  	evaluationCounts = Hash.new
	  	# create hashmap that maps student id's to the number
	  	# of evaluations they have for this assignment
	  	courseStudents.map { |student| 
	  		evaluationCounts[student.id] = evaluations.forUser(student).count		
	  	}
	  	reviewThreshold = evaluationCounts.values.min
	  	evaluationsLeft = self.assignment.reviews_required
	  	evaluatorPool = []
	  	begin
	  		# get students that have the lowest number of evaluations alreaddy assigned
	  		evaluatorPool.concat(courseStudents.select { |student|
	  			evaluationCounts[student.id] == reviewThreshold
	  		})
	  		# shuffle them because randomness
	  		evaluatorPool.shuffle!
	  		# Create evaluations for students until no more evaluations
	  		# are required or we run out of students
	  		while evaluatorPool.length > 0 && evaluationsLeft > 0
	  			evaluator = evaluatorPool.pop
	  			evaluation = Evaluation.new
					evaluation.submission_id = self.id
					evaluation.user_id = evaluator.id
					evaluation.save

					# create a response for each question of the evaluation
					self.assignment.questions.each { |question|  
						response = Response.new
						response.question_id = question.id
						response.evaluation_id = evaluation.id
						response.save!
					}

					evaluationsLeft -= 1
	  		end	
	  		# Increase the review threshold incase we ran out of students and need more
	 			reviewThreshold += 1
	  	end while evaluationsLeft > 0
	end
  	end
end
