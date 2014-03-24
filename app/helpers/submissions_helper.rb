module SubmissionsHelper
  def get_evaluations_for_submission_question(submission, question)
    rspns = []
    evaluations = Evaluation.where(submission_id: submission)
    evaluations.each do |eval|
      eval.responses.each do |resp|
        if resp.question == question then
          rspns << resp
        end
      end
    end
    return rspns
  end
end
