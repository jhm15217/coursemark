module SubmissionsHelper
  def response_for_question_by_peer(reviewer, submission, question)
    submission.evaluations.map{|e| e.responses.select{|r| test(r, reviewer, question)}[0]}.keep_if{|r| r}[0]
  end

  def test(r, reviewer, question)
    if r.evaluation
      r.question_id == question.id and r.evaluation.user_id == reviewer.id
    else
      puts 'Bad Response: ' + r.inspect
      r.destroy
      false
    end
  end

end