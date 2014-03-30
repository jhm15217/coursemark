class Evaluation < ActiveRecord::Base
  attr_accessible :submission_id, :user_id

  # Relationships
  has_many :responses
  belongs_to :submission
  belongs_to :user

  # Scopes
  scope :forUser, ->(user) {where("evaluations.user_id = ?", user.id)}

  def user_name
  	self.user.name
  end

end
