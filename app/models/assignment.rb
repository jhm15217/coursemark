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

  def status
    if Date.today <= (self.submission_due).to_date
      return "Submissions due " + self.submission_due.to_s(:pretty)
    elsif Date.today <= (self.review_due).to_date
      return "Reviews due " + self.review_due.to_s(:pretty)
    elsif Date.today > (self.review_due).to_date
      return "Reviews completed " + self.review_due.to_s(:pretty)
    end
  end

end