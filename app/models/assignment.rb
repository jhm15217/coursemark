class Assignment < ActiveRecord::Base
  require 'csv'
  attr_accessible :course_id, :draft, :manual_assignment, :reviewers_assigned, :review_due, :reviews_required
  attr_accessible :submission_due, :name, :submission_due_date, :submission_due_time, :review_due_date, :review_due_time, :team
  after_update :update_evaluations, :if => :reviews_required_changed?
  before_validation :make_dates

  # Relationships
  belongs_to :course
  has_many :submissions, dependent: :destroy
  has_many :questions, dependent: :destroy
  has_many :evaluations, :through => :submissions
  has_many :memberships, dependent: :destroy

  scope :published, -> { where(draft: false) }

  # Validations
  validates_numericality_of :reviews_required, :only_integer => true, :greater_than_or_equal_to  => 0

#  validates_datetime :submission_due, :allow_nil => true, :before => :review_due, :before_message => 'Submission deadline must be before review deadline'

  # submission and review due dates can only be changed if they haven't passed
  # validate :submission_deadline_not_passed
  # Extending the submission deadline might cause more reviews to be required, and the reviewers might not notice if they
  #    had completed all they initially had.
  # validate :review_deadline_not_passed
  # Extending the review deadline might allow a new review to come in after an instructor had declared the reviews for the
  #    submission finished.


  # make sure the number of reviews required is feasible given class size
#  validate :reviews_required_feasible
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

  # I chose to not make this a validation because it takes a while

   def publishable
    ok = true
    if questions.length == 0
      ok = false
      errors.add(:submission_due, 'You must first create a rubric.')
    end
    ok = reviews_required_feasible and ok
    if submission_due.nil? or review_due.nil? or submission_due > review_due
      ok = false
      errors.add(:submission_due, 'Submission deadline must be before review deadline')
    end
    ok
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

      self.memberships
    end
  end

  def get_participants_in_assignment
    course.get_people.select{|s| !s.pseudo or memberships.any?{|m| m.pseudo_user_id == s.id} }
  end

  def get_students_for_assignment
    self.course.get_people.select{|s| !s.instructor?(self.course) and !s.pseudo }
  end

  def reviews_for_user_to_complete(user)
    self.evaluations.forUser(user).select { |eval| !eval.finished  }
  end

  def get_submissions(user)
    # return current_user.submitting_user(assignment).submissions.first!
    ms = memberships.select{|m| m.user_id == user.id}
    if ms.length == 0
      Submission.where(:assignment_id => self.id, :user_id => user.id)
    else # This is a team assignment
      ms.map{|m| Submission.where(:assignment_id => self.id, :user_id => m.pseudo_user_id)}.flatten
    end
  end



  # get /assignments/1/export
  def export(students)
    reviewer_count =  submissions.map{|s| s.evaluations.length}.max
    space_before_questions =   ['']*(2 + reviewer_count)
    ordered_questions = questions.sort_by{ |obj| obj.created_at }
    return CSV.generate do |csv|
      line = Array.new(space_before_questions)
      ordered_questions.each {|question| line << question.question_text.gsub(',','<comma>'); line += ['']*(reviewer_count-1) }
      csv << line
      line = Array.new(space_before_questions)
      ordered_questions.each{|q|  line << q.question_weight; line += ['']*(reviewer_count-1) }
      csv << line

      header_row = ['Submitter', 'Time']
      chunk = []
      reviews_required.times { |index| chunk << "Reviewer #{index+1}" }
      header_row += chunk*(1 + ordered_questions.length)  + ['Reviews Finished', 'Reviews Requested']

      csv <<   header_row

      students.each do |student|
        this_sub = [student.email]
        submission = submissions.select { |sub| sub.user.id == student.submitting_id(self, sub) }.first
        if submission then
          this_sub << submission.created_at
          reviewer_shortfall = ['']*(reviewer_count-submission.evaluations.length)
          submission.evaluations.sort_by{|e| e.created_at }.each do |e|  # reveal who Reviewer1, Reviewer2, etc. were for this submission
            this_sub << e.user.email
          end
          this_sub += reviewer_shortfall
          # for each of the questions in the assignment
          ordered_questions.each do |question|
            points_for_q = []
            # get responses for a student's submission, sorted to match order in the reviewer page
            submission.get_responses_for_question(question).sort_by{|r| r.evaluation.created_at }.
                each_with_index do |response, index|    #this should match the reviewers names
              if response.evaluation.finished
                this_sub << response.scale.value
              else
                this_sub << ''
              end
            end
            this_sub += reviewer_shortfall
          end
        else
          this_sub += ['']*(1 + (reviewer_count)*(questions.length + 1))
        end

        this_sub << evaluations.forUser(student).select { |evaluation| evaluation.finished }.length
        this_sub << evaluations.forUser(student).length

        csv << this_sub
      end
    end
  end
    def put_emails(e)

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
    max_team_size = 1
    if team
      unless self.course.get_real_students.all?{|student| self.memberships.sum{|membership| membership.user_id == student.id ? 1 : 0} >= 1}
        errors.add(:team, 'Each student must be a member of at least one team.')
        return false
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

  end

  def submissions_open
    if submission_due < Time.now
      errors.add(:reviews_required, 'Can\'t change number of reviews required after submission deadline has passed.')
    end
  end

end