class Assignment < ActiveRecord::Base
  attr_accessible :course_id, :draft, :review_due, :reviews_required, :submission_due, :name

  after_update :update_evaluations, :if => :reviews_required_changed?

  # Relationships
  belongs_to :course
  has_many :submissions
  has_many :questions
  has_many :evaluations, :through => :submissions

  scope :published, -> { where(draft: false) }

  # Validations
  validates_inclusion_of :draft, :in => [true, false], :message => "must be true or false"
  validates_numericality_of :reviews_required, :only_integer => true, :greater_than_or_equal_to  => 0
  validates_datetime :submission_due, :allow_nil => true, :before => :review_due, :before_message => "Submission deadline must be before review deadline"
  validates_datetime :review_due, :allow_nil => true, :after => :submission_due, :after_message => "Review deadline must be after submission deadline"
  
  # submission and review due dates can only be changed if they haven't passed
  validate :submission_deadline_not_passed
  validate :review_deadline_not_passed

  # make sure the number of reviews required is feasible given class size
  validate :reviews_required_feasible
  # only allow changes to reviews_required if we are still taking submissions
  validate :submissions_open, :on => :update, :if => :reviews_required_changed?

  def status
    if (self.id.nil?)
      return
    end
    if Time.zone.now <= self.submission_due
      return "Submissions due " + self.submission_due.to_s(:pretty)
    elsif Time.zone.now <= self.review_due
      return "Reviews due " + self.review_due.to_s(:pretty)
    elsif Time.zone.now > self.review_due
      return "Reviews completed " + self.review_due.to_s(:pretty)
    end
  end

  def totalPoints
    self.questions.map{|q| q.question_weight}.reduce(:+)
  end

  def allGradesApproved?
    if (self.submissions.length == 0)
      return false
    end

    self.submissions.each do |submission|
      if (submission.instructor_approved != true)
        return false
      end
    end

    return true
  end

  private
  def submission_deadline_not_passed
    if self.submission_due < Time.now and self.submission_due.to_i != self.submission_due_was.to_i
      errors.add(:submission_due, "Can't change submission deadline after it has passed")
    end
  end

  def review_deadline_not_passed
    if self.review_due < Time.now and self.review_due.to_i != self.review_due_was.to_i
      errors.add(:review_due, "Can't change review deadline after it has passed")
    end
  end
  
  def update_evaluations
    self.submissions.each {|submission| submission.save!}
  end

  def reviews_required_feasible
    if self.course.get_students.length < reviews_required
      errors.add(:reviews_required, "Too many reviews required for class size.")
    end
  end

  def submissions_open
    if submission_due < Time.now
      errors.add(:reviews_required, "Can't change number of reviews required after submission deadline has passed.")
    end
  end
end