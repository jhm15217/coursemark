class Evaluation < ActiveRecord::Base
  attr_accessible :submission_id, :user_id, :finished

  # Relationships
  has_many :responses, dependent: :destroy
  belongs_to :submission
  belongs_to :user
  has_many :questions, :through => :responses

  # Scopes
  scope :forUser, ->(user) {where("evaluations.user_id = ?", user.id)}
  scope :forSubmission,
        ->(submission) {where("evaluations.submission_id = ?", submission.id)}

  def user_name
    self.user.name
  end

  def is_complete?
    return self.responses.all? { |response| response.is_complete? }
  end

  def incomplete_responses
    return self.responses.select { |response| !response.is_complete? }
  end

  def destroy
    super
    # Response.check     # This is an expensive check that simply culls orphaned responses
  end
end
