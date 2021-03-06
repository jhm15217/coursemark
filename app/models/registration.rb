class Registration < ActiveRecord::Base
  attr_accessible :active, :course_id, :instructor, :user_id, :course_code, :section, :sort_key

  # Relationships
  belongs_to :user
  belongs_to :course

  def email
    user.email
  end

  def first_name
    user.first_name
  end

  def last_name
    user.last_name
  end

  def pseudo
    user.pseudo
  end

  def pseudo= (b)
    user.pseudo = b
  end

  # Helpers
  def name
    first_name + ' ' + last_name
  end

  def instructor?(course)
      course_id == course.id and instructor
  end

  def registration_in(course)
   course.id == course_id ? self : nil
  end



# Validations
  validates_inclusion_of :active, :in => [true, false], :message => "must be true or false"
  validates_inclusion_of :instructor, :in => [true, false], :message => "must be true or false"

end
