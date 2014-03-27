class User < ActiveRecord::Base
  acts_as_authentic
  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation

  # Relationships
  has_many :evaluations
  has_many :submissions
  has_many :registrations
  has_many :courses, :through => :registrations
  has_many :assignments, :through => :courses

  # Validations
  validates :password, presence: { on: :create }, length: { minimum: 8, allow_blank: true }
  validates_uniqueness_of :email

  # Helpers
  def name 
		self.first_name.concat(' ').concat(self.last_name)
	end

  def instructor?(course)
    self.registrations.each do |registration|
      if registration.course == course
        if registration.instructor
          if registration.user == self
            return true
          end
        end
      end
    end

    return false
  end
end