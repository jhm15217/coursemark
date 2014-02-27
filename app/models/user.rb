class User < ActiveRecord::Base
  attr_accessible :email, :first_name, :last_name, :password, :password_digest

  # Relationships
  has_many :evaluations
  has_many :submissions
  has_many :registrations

  def name 
		self.first_name.concat(' ').concat(self.last_name)
	end
  
end