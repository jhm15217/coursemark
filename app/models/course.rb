class Course < ActiveRecord::Base
  before_create :create_unique_identifier
  attr_accessible :name, :course_code

  # Relationships
  has_many :registrations, dependent: :destroy
  has_many :assignments, dependent: :destroy
  has_many :users, :through => :registrations

  # These scopes don't work, and I don't know why
  scope :students, -> {joins(:users).where("instructor = 'f'")}
  scope :instructors, -> {joins(:users).where("instructor = 't'")}

  def register(user)
    Registration.new({active: false, instructor: false, course_code: self.course_code, user_id: user.id, course_id: self.id}).save!
  end

  def to_do(user)
    to_do_list = []
    assignments.each do  |assignment|  get_tasks(assignment, user, to_do_list) end
    to_do_list.sort{|a,b| a[:time] == b[:time] ? a[:index] <=> b[:index] : a[:time] <=> b[:time] }
  end

  def get_tasks(assignment, user, to_do_list)
    unless assignment.draft
      if Time.zone.now < assignment.submission_due
        if assignment.team
          team_ids = user.memberships.select{|m| m.assignment_id == assignment.id }.map{|m| m.pseudo_user_id }.
              select{|pui| !assignment.submissions.any?{|s| s.user_id == pui}}
          team_ids.each{|tid| to_do_list << {action: :submit, assignment: assignment, team: User.find(tid).name, time: assignment.submission_due - 2.hours }}
        elsif assignment.get_submissions(user)[0].nil?
          to_do_list << {action: :submit, assignment: assignment, time: assignment.submission_due - 2.hours }
        end
      elsif Time.zone.now <  assignment.review_due and assignment.are_reviewers_assigned
        assignment.evaluations.forUser(user).sort_by{|t| t.created_at}.each_with_index do |evaluation, index|
          unless evaluation.finished
            to_do_list << {action: :review, index: index + 1, submission_id: evaluation.submission.id, assignment: assignment,
                           time: assignment.review_due - 2.hours }
          end
        end
      end
    end
  end

  # The SQL for the booleans on instructor might not work when not on SQLite
  # Here are these instead
  def get_students
    registrations.select{|r| !r.instructor}.map{|r| r.user}
  end

  def get_real_students
    get_students.select{|s| !s.pseudo }
  end

  def get_people
    registrations.map{|r| r.user}
  end

  def get_instructors
    registrations.select{|r| r.instructor}.map{|r| r.user}
  end

  def create_unique_identifier
    begin
      self.course_code = SecureRandom.hex(4)
    end while self.class.exists?(:course_code => course_code)
  end
end
