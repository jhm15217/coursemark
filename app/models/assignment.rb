class Assignment < ActiveRecord::Base
  attr_accessible :course_id, :draft, :review_due, :reviews_required, :submission_due, :name

  # Relationships
  belongs_to :course
  has_many :submissions
  has_many :questions

  scope :published, -> { where(draft: false) }

  # Validations
  #validates_numericality_of :course_id, :only_integer => true, :greater_than => 0
  validates_inclusion_of :draft, :in => [true, false], :message => "must be true or false"
  validates_date :review_due
  validates_numericality_of :reviews_required, :only_integer => true, :greater_than => 0
  validates_date :submission_due

end
