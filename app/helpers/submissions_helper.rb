module SubmissionsHelper
  def response_for_question_by_peer(reviewer, submission, question)
    Response.where(question_id: question.id).select{|r| r.evaluation.user_id == reviewer.id and r.evaluation.submission_id == submission.id}.first
  end
end