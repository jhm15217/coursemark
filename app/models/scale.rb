class Scale < ActiveRecord::Base
  attr_accessible :description, :question_id, :value

  # Relationships
  has_many :responses
  belongs_to :question

  def new
    value = 0
  end

  # Validations
  validates_numericality_of :value, only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100


end
