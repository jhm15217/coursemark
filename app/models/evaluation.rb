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

  def mark_incomplete_questions
    all_complete = true
    responses.each do |response|
      start_flag = response.question.question_text.index(' [PLEASE FINISH]')
      if response.is_complete?
        if start_flag
          response.question.question_text= response.question.question_text.slice(0..start_flag)
          response.question.save!
        end
      else
        all_complete = false
        unless start_flag
          response.question.question_text= response.question.question_text +  ' [PLEASE FINISH]'
          response.question.save!
        end
      end
    end
    all_complete
  end

  def destroy
    super
    # Response.check     # This is an expensive check that simply culls orphaned responses
  end
end
