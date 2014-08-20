class Submission < ActiveRecord::Base
  attr_accessible :assignment_id, :attachment, :user_id, :instructor_approved
  has_attached_file :attachment
  after_save :assign_enough_review_tasks

  # Relationships
  belongs_to :user
  belongs_to :assignment
  has_many :evaluations, dependent: :destroy
  has_many :responses, :through => :evaluations

  MAX_FILE_SIZE = 15 # MegaBytes

  # Validations
  validates_presence_of :assignment_id
  validates_presence_of :user_id
  validate :met_deadline, :on => :create
  validates_attachment_size :attachment, :less_than => MAX_FILE_SIZE.megabytes, message: "File must be smaller than #{MAX_FILE_SIZE}MB. In MSW: File>Reduce File Size."
  validates_attachment_content_type :attachment, :content_type => ['application/pdf']

    def completed_responses
    completed = []
    responses.each do |response|
      if response.evaluation.finished   # Count only published reviews
        completed << response
      end
    end
    return completed
  end

  def evaluations_assigned
    assignment.evaluations.forUser(user)
  end

  def evaluations_completed
    assignment.evaluations.forUser(user).select {|evaluation| evaluation.is_complete?}
  end

  def grade
    # Get only completed responses
    responses = completed_responses
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
          questions[response.question_id]  = question
        end
      end
      questions.map{ |k, v|(v[:total].fdiv(v[:responses])) * v[:weight]}.reduce(:+).fdiv(assignment.total_points)
    else
      nil
    end
  end


  def met_deadline
    if Time.now > assignment.submission_due
      errors.add(:submission, "Deadline for assignment submission has passed.")
    end
  end

  def assign_enough_review_tasks
    create_evaluations(assignment.reviews_required  - evaluations.length,
                       assignment.course.get_real_students.
                           select{|s| s.submitting_id(assignment) != user_id and #not on same team
                           !evaluations.any?{|e| e.user_id == s.id} })  #not already reviewing

  end

  def create_evaluations(required, eligible_reviewers)
    evaluationCounts = Hash.new
    # create hashmap that maps reviewers' id's to the number
    # of evaluations they already have for this assignment
    eligible_reviewers.map { |r| evaluationCounts[r.id] = assignment.evaluations.forUser(r).count }
    reviewThreshold = evaluationCounts.values.min || 0
    evaluationsLeft = required
    evaluatorPool = []
    while evaluationsLeft > 0
      # get reviewers that have the lowest number of evaluations already assigned
      evaluatorPool.concat(eligible_reviewers.select { |r| evaluationCounts[r.id] == reviewThreshold })
      # shuffle to achieve randomness
      evaluatorPool.shuffle!
      # Create evaluations for submission until no more are required or we run out of reviewers
      while evaluatorPool.length > 0 && evaluationsLeft > 0
        evaluator = evaluatorPool.pop
        evaluation = Evaluation.new(submission_id: id, user_id: evaluator.id)
        evaluation.save!
        # create a response for each question of the evaluation
        assignment.questions.each { |question|
          response = Response.new(question_id: question.id, evaluation_id:evaluation.id )
          response.save!
        }
        evaluationsLeft -= 1
      end
      # Increase the review threshold in case we ran out of reviewers and need more
      reviewThreshold += 1
    end
  end


  def get_responses_for_question(question)
    responses.select{|resp| resp.question == question }
  end


end
