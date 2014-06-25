class Submission < ActiveRecord::Base
  attr_accessible :assignment_id, :attachment, :user_id, :instructor_approved
  has_attached_file :attachment
  after_save :create_and_save_evaluations

  # Relationships
  belongs_to :user
  belongs_to :assignment
  has_many :evaluations, dependent: :destroy
  has_many :responses, :through => :evaluations

  # Validations
  validates_presence_of :assignment_id
  validates_presence_of :user_id
  validate :met_deadline, :on => :create
  validates_attachment_size :attachment, :less_than => 15.megabytes
  validates_attachment_content_type :attachment, :content_type => ["application/pdf"]

  def completed_responses
  	completed = []
  	self.responses.each do |response|
  		if response.is_complete?
  			completed << response
  		end
  	end
  	return completed
  end

  def evaluations_assigned
  	self.assignment.evaluations.forUser(self.user)
  end

  def evaluations_completed
  	self.assignment.evaluations.forUser(self.user).select {|evaluation| evaluation.is_complete?}
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

  def met_deadline
  	if Time.now > self.assignment.submission_due
      errors.add(:submission, "Deadline for assignment submission has passed.")
    end	
  end

  def create_and_save_evaluations
  	# if reviews_required has since become infeasible
  	while ((self.assignment.course.get_real_students.length - 1) < self.assignment.reviews_required)
  		self.assignment.reviews_required = self.assignment.reviews_required - 1
  		self.assignment.save!
  	end

  	# only run if the number of evaluations isn't the number required
  	if self.evaluations.length != self.assignment.reviews_required
	  	self.evaluations.delete_all
	  	courseStudents = self.assignment.course.get_real_students.select{|s| s.submitting_id(assignment) != self.user_id }
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
	  		# get students that have the lowest number of evaluations already assigned
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

  def get_responses_for_question(question)
    responses.select{|resp| resp.question == question }
  end


end
