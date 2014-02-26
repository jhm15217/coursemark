class Question < ActiveRecord::Base
  attr_accessible :assignment_id, :question_text, :question_weight, :written_response_required

  # Relationships
  has_many :scales
  has_many :responses
  belongs_to :assignment

end