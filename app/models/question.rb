class Question < ActiveRecord::Base
  attr_accessible :assignment_id, :question_text, :question_weight, :written_response_required

  # Relationships
  has_many :scales
  has_many :responses
  belongs_to :assignment

  # Validations
  validates_inclusion_of :written_response_required, :in => [true, false], :message => "must be true or false"
  validates_numericality_of :question_weight, :only_integer => true, :greater_than => 0

end
