class Assignment < ActiveRecord::Base
  require 'csv'
  attr_accessible :course_id, :draft, :manual_assignment, :reviewers_assigned, :review_due, :reviews_required
  attr_accessible :instructor_reviews_required, :submission_due, :name, :submission_due_date, :submission_due_time, :review_due_date, :review_due_time, :team
  after_update :update_evaluations, :if => :reviews_required_changed?  or  :instructor_reviews_required_changed?
  before_validation :make_dates

  # Relationships
  belongs_to :course
  has_many :submissions, dependent: :destroy
  has_many :questions
  has_many :evaluations, :through => :submissions
  has_many :memberships, dependent: :destroy

  scope :published, -> { where(draft: false) }

  # Validations
  validates_inclusion_of :draft, :in => [true, false], :message => 'must be true or false'
  validates_numericality_of :reviews_required, :only_integer => true, :greater_than_or_equal_to  => 0
  validates_datetime :submission_due, :allow_nil => true, :before => :review_due, :before_message => 'Submission deadline must be before review deadline'
  validates_datetime :review_due, :allow_nil => true, :after => :submission_due, :after_message => 'Review deadline must be after submission deadline'

  # submission and review due dates can only be changed if they haven't passed
  # validate :submission_deadline_not_passed
  # Extending the submission deadline might cause more reviews to be required, and the reviewers might not notice if they
  #    had completed all they initially had.
  # validate :review_deadline_not_passed
  # Extending the review deadline might allow a new review to come in after an instructor had declared the reviews for the
  #    submission finished.


  # make sure the number of reviews required is feasible given class size
  validate :reviews_required_feasible
  # only allow changes to reviews_required if we are still taking submissions
  validate :submissions_open, :on => :update, :if => :reviews_required_changed?

  def status
    if self.id.nil?
      return
    end
    if Time.zone.now <= self.submission_due
      'Submissions due ' + self.submission_due.to_s(:pretty)
    elsif Time.zone.now <= self.review_due
      'Reviews due ' + self.review_due.to_s(:pretty)
    elsif Time.zone.now > self.review_due
      'Reviews completed ' + self.review_due.to_s(:pretty)
    end
  end

  def total_points
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
    submission_due.strftime('%m/%d/%Y') if submission_due.present?
  end

  def submission_due_time
    submission_due if submission_due.present?
  end

  def review_due_date
    review_due.strftime('%m/%d/%Y') if review_due.present?
  end

  def review_due_time
    review_due if review_due.present?
  end

  def submission_due_date=(date)
    @submission_due_date = Date.strptime(date, '%m/%d/%Y').strftime('%Y-%m-%d')
  end

  def submission_due_time=(time)
    @submission_due_time = Time.parse(time.to_s).strftime('%H:%M:%S')
  end

  def review_due_date=(date)
    @review_due_date = Date.strptime(date, '%m/%d/%Y').strftime('%Y-%m-%d')
  end

  def review_due_time=(time)
    @review_due_time = Time.parse(time.to_s).strftime('%H:%M:%S')
  end

  def make_dates
    @offset = Time.zone.now.to_s.split(' ')[2]

    if !@offset.nil? && !@submission_due_date.nil? && !@submission_due_time.nil? && !@review_due_date.nil? && !@review_due_time.nil?

      self.submission_due = DateTime.parse("#{@submission_due_date} #{@submission_due_time + @offset}")
      self.review_due = DateTime.parse("#{@review_due_date} #{@review_due_time + @offset}")

    end
  end

  def get_participants_in_assignment
    self.course.get_people.select{|s| !s.pseudo or self.memberships.select{|m| m.pseudo_user_id == s.id}.length > 0 }
  end

  def get_students_for_assignment
    self.course.get_people.select{|s| !s.instructor?(self.course) and !s.pseudo }
  end

  def reviews_for_user_to_complete(user)
    self.evaluations.forUser(user).select { |eval| !eval.finished  }
  end

  # get /assignments/1/export
  def export(students)
    header_row = ['Submitter', 'Time']
    reviews_required.times { |index| header_row << "Student #{index+1}" }
    instructor_reviews_required.times { |index| header_row << "Instructor #{index+1}" }
    questions.each { |question|
      header_row << question.question_text
      reviews_required.times { |index| header_row << "Student #{index+1}" }
      instructor_reviews_required.times { |index| header_row << "Instructor #{index+1}" }
    }
    header_row << 'Reviews Finished'
    header_row << 'Reviews Required'

    return CSV.generate do |csv|
      csv << header_row
      students.each do |student|
        this_sub = [student.email]
        submission = submissions.select { |sub| sub.user.id == student.submitting_id(self) }.first
        if submission then
          this_sub << submission.created_at
          submission.evaluations.sort_by{|e| e.created_at }.each do |e|
            this_sub << e.user.email
          end
          # for each of the questions in the assignment
          self.questions.sort_by{ |obj| obj.created_at }.each do |question|
            # total possible points
            this_sub << question.question_weight

            points_for_q = []
            # get responses for a student's submission, sorted to match order in the reviewer page
            submission.get_responses_for_question(question).sort_by{|r| r.evaluation.created_at }.each_with_index do |response, index|
              if response.evaluation.finished
                this_sub << (((100 / (response.question.scales.length - 1.0) * response.scale.value)) / 100) * question.question_weight
              else
                this_sub << ''
              end
            end
          end
        else
          this_sub += ['']*((1 + reviews_required + instructor_reviews_required )*(questions.length + 1))
        end

        this_sub << evaluations.forUser(student).select { |evaluation| evaluation.finished }.length
        this_sub << evaluations.forUser(student).length

        csv << this_sub
      end
    end
  end






  private
  def submission_deadline_not_passed
    if self.submission_due > Time.now and self.submission_due.to_i != self.submission_due_was.to_i
      errors.add(:submission_due, 'Can\'t change submission deadline if it has passed')
    end
  end

  def review_deadline_not_passed
    if self.review_due > Time.now and self.review_due.to_i != self.review_due_was.to_i
      errors.add(:review_due, 'Can\'t change review deadline if it has passed')
    end
  end

  def update_evaluations
    self.submissions.each {|submission| submission.save!}
  end

  def reviews_required_feasible
    if draft
      return true # maybe the assignment is being created before all people enroll
    end
    max_team_size = 1
    if team
      unless self.course.get_real_students.all?{|student| self.memberships.sum{|membership| membership.user_id == student.id ? 1 : 0} == 1}
        errors.add(:teams_ok, 'Each student must be a member of one team.')
      end
      #Figure out max team size
      team_count = Hash.new(0)
      self.memberships.each{|membership| team_count[membership.team] += 1}
      max_team_size = (team_count.values.max or 1)
    end
    # if reviews_required has since become infeasible
    if self.course.get_real_students.length - max_team_size < reviews_required
      errors.add(:reviews_required, 'At most ' + (self.course.get_real_students.length - max_team_size).to_s + ' student reviews can be required.')
    end
    if self.course.get_instructors.length < instructor_reviews_required
      errors.add(:reviews_required, 'At most ' + (self.course.get_instructors.length.to_s + ' instructor reviews can be required.'))
    end
  end

  def submissions_open
    if submission_due < Time.now
      errors.add(:reviews_required, 'Can\'t change number of reviews required after submission deadline has passed.')
    end
  end

end