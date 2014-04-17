class Assignment < ActiveRecord::Base
  attr_accessible :course_id, :draft, :review_due, :reviews_required, :submission_due, :name, :submission_due_date, :submission_due_time, :review_due_date, :review_due_time
  after_update :update_evaluations, :if => :reviews_required_changed?
  before_validation :make_dates

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

  def submission_due_date
    submission_due.strftime("%m/%d/%Y") if submission_due.present?
  end
 
  def submission_due_time
    submission_due if submission_due.present?
  end
 
  def review_due_date
    review_due.strftime("%m/%d/%Y") if review_due.present?
  end

  def review_due_time
    review_due if review_due.present?
  end
 
  def submission_due_date=(date)
    @submission_due_date = Date.strptime(date, "%m/%d/%Y").strftime("%Y-%m-%d")
  end
 
  def submission_due_time=(time)
    @submission_due_time = Time.parse(time.to_s).strftime("%H:%M:%S")
  end
 
  def review_due_date=(date)
    @review_due_date = Date.strptime(date, "%m/%d/%Y").strftime("%Y-%m-%d")
  end

  def review_due_time=(time)
    @review_due_time = Time.parse(time.to_s).strftime("%H:%M:%S")
  end
  
  def make_dates
    if !@submission_due_date.nil?
      @offset = Time.zone.now.to_s.split(' ')[2]
      self.submission_due = DateTime.parse("#{@submission_due_date} #{@submission_due_time + @offset}")
      puts self.submission_due
      self.review_due = DateTime.parse("#{@review_due_date} #{@review_due_time + @offset}")
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