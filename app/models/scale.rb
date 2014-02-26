class Scale < ActiveRecord::Base
  attr_accessible :description, :question_id, :value

  # Relationships
  has_many :responses
  belongs_to :question
  
end