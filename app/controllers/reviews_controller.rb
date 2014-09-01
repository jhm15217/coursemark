class ReviewsController < ApplicationController
  before_filter :get_assignment, :get_course

  def index
    authorize! :manage, :reviews

    @students = sorted(@assignment.get_participants_in_assignment)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # POST /reviewers
  # POST /reviewers.json
  # The csv file has no labels and lines of the form [submitter-email,(reviewer-email)*]
  def create
    @course = Course.find(params[:course_id])
    @assignment = Assignment.find(params[:assignment_id])
    if params[:clear_reviewers]
      @assignment.evaluations.each{|e| e.destroy }
    end
    if params[:add_required]
      @assignment.add_required
    else
      params[:response][:reviewers].split("\r\n").each{ |line| add_submission(line.split(',').map{|s| s.strip}) }
    end
    respond_to do |format|
      format.html { redirect_to course_assignment_reviews_path(@course,@assignment) }
      format.json { render json: @reviewers, status: :created, location: @reviewers }
    end
  end

def add_submission(row)
  if row[0] and submitter = find_registrant(@course, row[0]) and submission = @assignment.submissions.select{|s| s.user_id == submitter.id}[0]
    i = 1
    while row[i]
      if reviewer = find_registrant(@course, row[i])
        if !@assignment.evaluations.select{|e| e.submission == submission and e.user == reviewer }[0]
          e = Evaluation.new(submission_id: submission.id, user_id: reviewer.id)
          e.save!
          @assignment.questions.each { |q| Response.new(evaluation_id: e.id, question_id: q.id).save! }
        end
      end
      i +=1
    end
  end
end

def assign_reviews
  authorize! :manage, :reviews

  @assignment.reviewers_assigned = !@assignment.reviewers_assigned
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
