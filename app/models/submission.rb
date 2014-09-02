class Submission < ActiveRecord::Base
  attr_accessible :assignment_id, :attachment, :user_id, :instructor_approved
  has_attached_file :attachment

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

  def save
    puts "SAVING ATTACHMENT " + self.inspect
    super
    assignment.initialize_reviewers
    assign_enough_review_tasks(assignment.initialize_reviewers)
  end

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

  def assign_enough_review_tasks(reviewers)
    create_evaluations(assignment.reviews_required  - evaluations.length, reviewers)
  end

  def create_evaluations(required, reviewers)
    candidates = reviewers
    disqualified = []
    while required > 0
      review_count = candidates.next_key
      candidate = candidates.pop
      if candidate.submitting_id(assignment, self) == user_id or evaluations(true).any?{|e| e.user_id == candidate.id}
        disqualified << { key: review_count, value: candidate }
      else
        evaluation = Evaluation.new(submission_id: id, user_id: candidate.id)
        evaluation.save!
        # create a response for each question of the evaluation
        assignment.questions.each { |question| Response.new(question_id: question.id, evaluation_id:evaluation.id ).save! }
        required -= 1
        candidates.push(review_count + 1, candidate)   # put back in pool
      end
    end
    disqualified.each{|pair| candidates.push(pair[:key], pair[:value])}  # put back in pool with original key
  end



  def get_responses_for_question(question)
    responses.select{|resp| resp.question == question }
  end


end
