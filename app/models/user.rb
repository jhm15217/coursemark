class User < ActiveRecord::Base
  attr_accessible :email, :first_name, :last_name, :password, :password_digest

  # Relationships
  has_many :evaluations
  has_many :submissions
  has_many :registrations

  # Validations
  validates_presence_of :email, :password, :password_digest
  validates_uniqueness_of :email


  #Helpers
  def name
		self.first_name.concat(' ').concat(self.last_name)
	end

end
