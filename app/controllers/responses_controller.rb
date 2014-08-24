class ResponsesController < ApplicationController
  before_filter :get_assignment, :get_course, :get_question
#  load_and_authorize_resource :except => [:update]

  # GET /responses
  # GET /responses.json
  def index
    @responses = Response.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @responses }
    end
  end

  # GET /responses/1
  # GET /responses/1.json
  def show
    @response = Response.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @response }
    end
  end

  # GET /responses/new
  # GET /responses/new.json
  def new
    @response = Response.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @response }
    end
  end

  # GET /responses/1/edit
  def edit
    @response = Response.find(params[:id])
  end

  # POST /responses
  # POST /responses.json
  def create
    @response = Response.new(params[:response])

    respond_to do |format|
      if @response.save
        format.html { redirect_to @response, notice: 'Response was successfully created.' }
        format.json { render json: @response, status: :created, location: @response }
      else
        format.html { render action: "new" }
        format.json { render json: @response.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /responses/1
  # PUT /responses/1.json
  def update
    @response = Response.find(params[:id])
    submitter_id =  current_user.submitting_id(get_assignment, @response.evaluation.submission)

    if ((!current_user.instructor?(@course)) && (current_user.id != @response.evaluation.user_id) && (submitter_id != @response.evaluation.submission.user_id))
      raise CanCan::AccessDenied.new("Not authorized!")
    end

    @URL = course_assignment_path(@course, @assignment)

    if (current_user.instructor?(@course))
      @URL = course_assignment_submission_path(@course, @assignment, @response.evaluation.submission) + '?instructor=true'
    elsif (submitter_id == @response.evaluation.submission.user_id) and params[:response]
      @response.student_response =  params[:response][:student_response]
    end

    respond_to do |format|
      if @response.update_attributes(params[:response])
        format.html { redirect_to @URL, notice: "#{@response.errors.full_messages.join(' ')}"}
        format.json { render json: @response}
      else
        format.html { redirect_to @URL, notice: "#{@response.errors.full_messages.join(' ')}"}
        format.json { render json: @response.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /responses/1
  # DELETE /responses/1.json
  def destroy
    @response = Response.find(params[:id])
    @response.destroy

    respond_to do |format|
      format.html { redirect_to responses_url }
      format.json { head :no_content }
    end
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

  def get_question
    if params[:question_id]
      @question = Question.find(params[:question_id])
    end
  end
end
