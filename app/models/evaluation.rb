class Evaluation < ActiveRecord::Base
  attr_accessible :submission_id, :user_id

  # Relationships
  has_many :responses, dependent: :destroy
  belongs_to :submission
  belongs_to :user

  # Scopes
  scope :forUser, ->(user) {where("evaluations.user_id = ?", user.id)}

  def user_name
  	self.user.name
  end

  def is_complete?
    self.responses.each do |response|
      if (response.is_complete? == false)
        return false
      end
    end

    return true
  end
end