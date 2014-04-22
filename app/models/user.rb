class User < ActiveRecord::Base
  acts_as_authentic
  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation

  # Relationships
  has_many :evaluations
  has_many :submissions
  has_many :registrations
  has_many :courses, :through => :registrations
  has_many :assignments, :through => :courses

  # Get all users except the given user
  scope :without_user, ->(user) {where("user_id != ?", user.id)}


  # Validations
  validates :password, presence: { on: :create }, length: { minimum: 8, allow_blank: true }
  validates_uniqueness_of :email

  # Helpers
  def name 
		self.first_name + ' ' + self.last_name
	end

  def instructor?(course)
    self.registrations.each do |registration|
      if registration.course_id == course.id
        if registration.instructor
          return true
        end
      end
    end

    return false
  end
end