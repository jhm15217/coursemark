class Assignment < ActiveRecord::Base
  require 'csv'
  attr_accessible :course_id, :draft, :manual_assignment, :reviewers_assigned, :review_due, :reviews_required, :submission_due, :name, :submission_due_date, :submission_due_time, :review_due_date, :review_due_time, :team
  after_update :update_evaluations, :if => :reviews_required_changed?
  before_validation :make_dates

  # Relationships
  belongs_to :course
  has_many :submissions
  has_many :questions
  has_many :evaluations, :through => :submissions
  has_many :memberships

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
  validate :reviews_required_feasible, :unless => :draft
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

  def missing_submissions
    self.course.get_students - (self.submissions.map {|submission| submission.user})
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
    @offset = Time.zone.now.to_s.split(' ')[2]

    if (!@offset.nil? && !@submission_due_date.nil? && !@submission_due_time.nil? && !@review_due_date.nil? && !@review_due_time.nil?)

      self.submission_due = DateTime.parse("#{@submission_due_date} #{@submission_due_time + @offset}")
      self.review_due = DateTime.parse("#{@review_due_date} #{@review_due_time + @offset}")

    end
  end

  def get_students_for_assignment
    self.course.get_students.select{|s| !s.pseudo or self.memberships.select{|m| m.pseudo_user_id == s.id}.length > 0 }
  end

  def reviews_for_user_to_complete(user)
    self.evaluations.forUser(user).select { |eval| !eval.finished  }
  end

  # get /assignments/1/export
  def export
    @students = Course.find(course_id).get_students_for_assignment.sort_by { |s| s.first_name }.sort_by { |s| s.last_name }.sort_by{|s| s.pseudo ? 0 : 1}
    header_row = ["Name", "Total Points", "Total Possible Points", "Percentage"]
    questions.each { |question|
      header_row << question.question_text
      header_row << "Possible Points"
      reviews_required.times { |index|
        header_row << "Reviewer #{index+1}"
      }
    }
    header_row << "Reviews Finished"
    header_row << "Reviews Required"

    return CSV.generate do |csv|
      csv << header_row
      @students.each do |student|
        submission = submissions.select { |sub| sub.user.id == student.submitting_id(self) }.first
        if submission then
          if !submission.percentage.blank? then
            percent = submission.percentage.round
          else
            percent = ""
          end
          this_sub = [student.name, submission.raw, totalPoints, percent]
          # for each of the questions in the assignment
          submission.responses.sort_by { |obj| obj.created_at }.uniq { |x| x.question_id }.each do |res|

            points_for_q = []

            # get responses for a student's submission
            submission.get_responses_for_question(res.question).each_with_index do |response, index|
              if response.is_complete?
                points = (((100 / (response.question.scales.length - 1.0) * response.scale.value)) / 100) * res.question.question_weight
                #points = (response.question.question_weight / (response.question.scales.length - 1.0) * response.scale.value)
                points_for_q << points
              end
            end
            # average points someone got for question
            this_sub << (points_for_q.inject(:+).to_f / points_for_q.length) #.inject{ |sum, el| sum + el }.to_f / points_for_q.size

            # total possible points
            this_sub << res.question.question_weight

            # for each peer response, record their grade of the assignment
            points_for_q.each do |point|
              this_sub << point
            end
          end
        else
          this_sub = [student.name, 0, totalPoints, 0] + ([0, 0] + [0]*reviews_required)*questions.length
        end

        this_sub << evaluations.forUser(student).select { |evaluation| evaluation.is_complete? }.length
        this_sub << evaluations.forUser(student).length

        csv << this_sub
      end
    end

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
    if (self.course.get_students.length - 1) < reviews_required
      errors.add(:reviews_required, "Too many reviews required for class size.")
    end
  end

  def submissions_open
    if submission_due < Time.now
      errors.add(:reviews_required, "Can't change number of reviews required after submission deadline has passed.")
    end
  end

end
