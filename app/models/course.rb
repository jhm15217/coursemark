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
