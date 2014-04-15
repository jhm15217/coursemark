module ApplicationHelper
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

  	def prettifyFloat x
	  Float(x)
	  i, f = x.to_i, x.to_f
	  i == f ? i : f
	rescue ArgumentError
	  x
	end
end
