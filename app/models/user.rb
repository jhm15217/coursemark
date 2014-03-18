class User < ActiveRecord::Base
  acts_as_authentic
  attr_accessible :email, :first_name, :last_name, :password, :password_confirmation

  # Relationships
  has_many :evaluations
  has_many :submissions
  has_many :registrations

  # Validations
  validates :password, presence: { on: :create }, length: { minimum: 8, allow_blank: true }
  validates_uniqueness_of :email

  # Helpers
  def name 
		self.first_name.concat(' ').concat(self.last_name)
	end
end