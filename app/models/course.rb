class Course < ActiveRecord::Base
  before_create :create_unique_identifier
  attr_accessible :name, :course_code

  # Relationships
  has_many :registrations
  has_many :assignments
  has_many :users, :through => :registrations

  # These scopes don't work, and I don't know why
  scope :students, -> {joins(:users).where("instructor = 'f'")}
  scope :instructors, -> {joins(:users).where("instructor = 't'")}

  # Here are these instead
  # The SQL for the booleans on instructor might not work when noto n SQLite
  def get_students
  	User.joins(:courses).where("course_id = ?",self.id).where("instructor = 'f'")
  end

  def get_instructors
  	User.joins(:courses).where("course_id = ?",self.id).where("instructor = 't'")
  end

  def create_unique_identifier
    begin
      self.course_code = SecureRandom.hex(4)
    end while self.class.exists?(:course_code => course_code)
  end
end
