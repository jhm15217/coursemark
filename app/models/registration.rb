class Registration < ActiveRecord::Base
  attr_accessible :active, :course_id, :instructor, :user_id

  # Relationships
  belongs_to :user
  belongs_to :course

  # Validations
  validates_inclusion_of :active, :in => [true, false], :message => "must be true or false"
  validates_inclusion_of :instructor, :in => [true, false], :message => "must be true or false"

end
