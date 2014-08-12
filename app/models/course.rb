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
    assignments.each do  |assignment|
      unless assignment.draft
        if Time.now < assignment.submission_due and assignment.get_submission(user).nil?
          to_do_list << {action: :submit, assignment: assignment, time: assignment.submission_due - 2.hours }
          puts "to_do: " + to_do.inspect
        end
        if Time.now > assignment.submission_due and Time.now < assignment.review_due and assignment.reviewers_assigned
          assignment.evaluations.forUser(current_user).sort_by{|t| t.created_at}.each_with_index do |evaluation, index|
            unless evaluation.finished
              to_do_list << {action: :review, index: index + 1, submission_id: evaluation.submission.id, assignment: assignment,
                         time: assignment.review_due - 2.hours }
            end
          end
        end
      end
    end
    puts "final to_do: " + to_do.inspect
    to_do_list.sort_by{|t| t[:time] }
  end

  # Here are these instead
  # The SQL for the booleans on instructor might not work when not on SQLite
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
