# == Schema Information
#
# Table name: users
#
#  id                     :integer         not null, primary key
#  first_name             :string(255)
#  last_name              :string(255)
#  email                  :string(255)
#  password               :string(255)
#  password_confirmation  :string(255)
#  confirmed              :boolean         default(FALSE)
#  confirmation_token     :string(255)
#  password_reset_sent_at :datetime


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

  def send_password_reset
    generate_confirmation_token
    self.password_reset_sent_at = Time.now
    save!(validate: false)

    UserMailer.password_reset(self).deliver
  end

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64
  end

  def get_submission(assignment)
    self.submissions.each do |submission|
      if submission.assignment_id == assignment.id
        return submission
      end
    end
    return nil
  end

  # Active Record Callbacks
  before_save { |user|
    user.email = email.downcase
    if user.new_record?
      user.generate_confirmation_token
    end


  }

  #Validations
  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[_a-z0-9-]+(\.[_a-z0-9-]+)*@[a-z0-9-]+(\.[a-z0-9-]+)*(\.[a-z]{2,4})\z/i
  validates :email, presence:   true,
            format:     { with: VALID_EMAIL_REGEX },
            uniqueness: { case_sensitive: false }
  validates :password_confirmation, presence: true
  validates :password, presence: { on: :create }, length: { minimum: 8, allow_blank: true }
  validates_uniqueness_of :email

end
