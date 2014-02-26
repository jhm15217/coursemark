class User < ActiveRecord::Base
  attr_accessible :email, :first_name, :last_name, :password, :password_digest

  # Relationships
  has_many :evaluations
  has_many :submissions
  has_many :registrations
  
end