class Registration < ActiveRecord::Base
  attr_accessible :active, :course_id, :instructor, :user_id, :course_code

  # Relationships
  belongs_to :user
  belongs_to :course


  def sorted
    self.sort { |a,b|
      a = a.user
      b = b.user
      a.pseudo != b.pseudo ? (a.pseudo ? -1 : 1) :
      a.last_name != b.last_name ? a.last_name < b.last_name :
      a.first_name != b.first_name ? a.first_name < b.first_name :
      0 }
  end

# Validations
  validates_inclusion_of :active, :in => [true, false], :message => "must be true or false"
  validates_inclusion_of :instructor, :in => [true, false], :message => "must be true or false"

end
