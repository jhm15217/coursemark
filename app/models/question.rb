class Question < ActiveRecord::Base
  attr_accessible :assignment_id, :question_text, :question_weight, :written_response_required, :scales_attributes

  # Relationships
  has_many :scales, dependent: :destroy
  has_many :responses, dependent: :destroy
  belongs_to :assignment

  accepts_nested_attributes_for :scales, :allow_destroy => true, :reject_if => :all_blank

  # Validations
  validates_inclusion_of :written_response_required, :in => [true, false], :message => "must be true or false"
  validates_numericality_of :question_weight, :only_integer => true

end
