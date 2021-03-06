class Assignment < ActiveRecord::Base
  require 'csv'
  require 'algorithms'
  include Containers
  serialize :cached_sort, Array


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
  validate :publishable

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

  def to_do(user)
    to_do_list = []
    unless draft
      if Time.zone.now < review_due     # allow late submissions
        team_ids = []
        if team
          team_ids = user.memberships.select{|m| m.assignment_id == self.id }.map{|m| m.pseudo_user_id }.
              select{|pui| !submissions.any?{|s| s.user_id == pui}}
          team_ids.each{|tid| to_do_list << {action: :submit, team: User.find(tid).name, time: submission_due  }}
        end
        if team_ids.length == 0 and get_submissions(user)[0].nil?
          to_do_list << {action: :submit, time: submission_due }
        end
      end
      if are_reviewers_assigned
        evaluations.forUser(user).sort_by{|t| t.created_at}.each_with_index do |evaluation, index|
          unless evaluation.finished  or evaluation.submission.instructor_approved
            to_do_list << {action: :review, index: index + 1, submission_id: evaluation.submission.id, time: review_due }
          end
        end
      end
    end
    to_do_list.sort{|a,b| a[:time] == b[:time] ? a[:index] <=> b[:index] : a[:time] <=> b[:time] }
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

  def are_reviewers_assigned
    reviewers_assigned or !manual_assignment and Time.zone.now > submission_due
  end


  def publishable
    ok = true
    unless draft
      if questions.length == 0
        ok = false
        errors.add(:submission_due, 'You must first create a rubric.')
      end
      ok = reviews_required_feasible and ok
      if submission_due.nil? or review_due.nil? or submission_due > review_due
        ok = false
        errors.add(:submission_due, 'Submission deadline must be before review deadline.')
      end
      if team
        ms = memberships.all
        if ms.length == 0 or !ms.any?{|m| m.assignment_id == self.id }
          ok = false
          errors.add(:submission_due, "No teams have been assigned.")
        end
      end
    end
    ok
  end

  def getTeamID(user)
    memberships.each do |m|
      if m.user_id == user.id
        return m.pseudo_user_id
      end
    end
    return user.id
  end


=begin
    Assume there S students, which is enough to do R reviews per submission; this was guaranteed by
    required_reviews_feasible (below) checking that (S-T) >= R where T is the maximum team size.
    For various reasons, we need to assign reviewers as submissions come in, so we can't control the number of reviews
    each student performs directly.
    Suppose there are N teams. To be fair we don't want to assign any student more than ceiling(NR/S) reviews, so we use
    a priority heap to assign reviews first to the students with the fewest. However, since students can't review their
    own team's work, we could get trapped on the last submission if it happens that the only students left with the
    minimum number of reviews are all on the team that just submitted.
    The following bias trick insures that can't happen:
    A. We use a priority heap to assign R reviews to a submission when it comes in. Priority is given to the student with
       priority 2*(Number of reviews already assigned) + (if student has submitted yet ? 1 : 0). In other words, we are biased
       towards assigning reviews to students who haven't submitted yet.
    B. When the next-to-last submission comes in, the only potential reviewers with zero bias are submitters of the last one.
       Any who have the minimum number of reviews will be assigned to the next-to-last submission, because the required number
       of reviewers is always at least the maximum team size. Then, when the final submission comes in, all its submitters
       will have N+1 reviews. Any remaining people with N reviews will be assigned. If any with N+1 are then given an N+2nd review
       that's OK because nobody has N reviews.
=end



  def initialize_reviewers
    reviewers = MinHeap.new
    course.get_real_students.shuffle.each do |r|
      reviews =  evaluations.forUser(r)
      # Don't assign new reviews to someone who as completed all their reviews
      unless  reviews.length > 0 and reviews.length == reviews.select{|e| e.finished }.length
        # Create a bias towards assigning reviewers who have not yet submitted so as avoid entrapment by the self-review prohibition
        bias = submissions.any?{|s| s.user_id == getTeamID(r)}   ? 1 : 0
        reviewers.push(2 * reviews.length + bias, r)
      end
    end
    reviewers
  end


  def add_required
    reviewers =  initialize_reviewers
    submissions.each { |s| s.assign_enough_review_tasks(reviewers) }
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
        submission = submissions.select { |sub| sub.user.id == student.submitting_id(sub) }.first
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
    if self.submission_due > Time.zone.now and self.submission_due.to_i != self.submission_due_was.to_i
      errors.add(:submission_due, 'Can\'t change submission deadline if it has passed')
    end
  end

  def review_deadline_not_passed
    if self.review_due > Time.zone.now and self.review_due.to_i != self.review_due_was.to_i
      errors.add(:review_due, 'Can\'t change review deadline if it has passed')
    end
  end

  def update_evaluations
    self.submissions.each {|submission| submission.save!}
  end

  def reviews_required_feasible
    max_team_size = 1
    if team
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
    if submission_due < Time.zone.now
      errors.add(:reviews_required, 'Can\'t change number of reviews required after submission deadline has passed.')
    end
  end

end