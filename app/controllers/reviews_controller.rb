class ReviewsController < ApplicationController
  before_filter :get_assignment, :get_course

  def index
  	authorize! :manage, :reviews
  	
    @students = @assignment.get_students_for_assignment

  	respond_to do |format|
      format.html # index.html.erb
    end
  end

  def assign_reviews
    authorize! :manage, :reviews

    @assignment.reviewers_assigned = !@assignment.reviewers_assigned

    if @assignment.reviewers_assigned.nil?
      @assignment.reviewers_assigned = true
    end

    @assignment.save!

    redirect_to action: 'index'
  end

  def edit_review
    authorize! :manage, :reviews

    # Find existing evaluation
    @s = @assignment.submissions.where('user_id = ' + params['submitterID'])[0]
    @e = @s.evaluations.where('user_id = ' + params['oldReviewerID'])[0]

    # Delete existing evaluation
    if @e then @e.destroy end

    # Create new evaluation
    @e = Evaluation.new
    @e.submission = @s
    @e.user_id = params['newReviewerID']
    @e.save!

    # Create empty evaluation responses
    @assignment.questions.each { |question|  
      response = Response.new
      response.question_id = question.id
      response.evaluation_id = @e.id
      response.save!
    }

    puts params

    redirect_to action: 'index'
  end

  def get_assignment
    if params[:assignment_id]
      @assignment = Assignment.find(params[:assignment_id])
    end
  end

  def get_course
    if params[:course_id]
      @course = Course.find(params[:course_id])
    end
  end
end
