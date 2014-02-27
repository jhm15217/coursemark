class Evaluation < ActiveRecord::Base
  attr_accessible :submission_id, :user_id

  # Relationships
  has_many :responses
  belongs_to :submission
  belongs_to :user

  def user_name 
  	self.user.name 
  end
  
end