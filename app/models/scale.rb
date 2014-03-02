class Scale < ActiveRecord::Base
  attr_accessible :description, :question_id, :value

  # Relationships
  has_many :responses
  belongs_to :question

  # Validations
  validates_presence_of :question_id

end
