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
  validates_date :submission_due, :allow_nil => true
  validates_date :review_due, :allow_nil => true
  # submission and review due dates can only be changed if they haven't passed
  validates :submission_due, :deadline => true, :on => :update, :unless => :draft?, :if => :submission_due_changed?
  validates :review_due, :deadline => true, :on => :update, :unless => :draft?, :if => :review_due_changed?
  # make sure the number of reviews required is feasible given class size
  validate :reviews_required_feasible
  # only allow changes to reviews_required if we are still taking submissions
  validate :submissions_open, :on => :update, :if => :reviews_required_changed?

  def status
    if (self.id.nil?)
      return
    end
    if Date.today <= (self.submission_due).to_date
      return "Submissions due " + self.submission_due.to_s(:pretty)
    elsif Date.today <= (self.review_due).to_date
      return "Reviews due " + self.review_due.to_s(:pretty)
    elsif Date.today > (self.review_due).to_date
      return "Reviews completed " + self.review_due.to_s(:pretty)
    end
  end

  private
  def update_evaluations
    self.submissions.each {|submission| submission.save!}
  end

  def reviews_required_feasible
    if self.course.get_students.length < reviews_required
      errors.add(:reviews_required, "Too many reviews required for class size.")
    end
  end

  def submissions_open
    if submission_due < Date.today
      errors.add(:reviews_required, "Can't change number of reviews required after submission deadline has passed.")
    end
  end
end