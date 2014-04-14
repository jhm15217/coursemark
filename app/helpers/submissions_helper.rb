module SubmissionsHelper
	def response_for_question_by_peer(reviewer, submission, question)
  		# Response.where("evaluation.user_id = ? AND evaluation.submission_id = ? AND question_id = ?", reviewer.id, submission.id, question.id)
  		# Response.where(:evaluation_id.user_id => reviewer.id, :evaluation_id.submission_id => submission.id, :question_id => question.id)
  	end
end
