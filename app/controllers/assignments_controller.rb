class AssignmentsController < ApplicationController
  before_filter :get_course
  helper_method :get_submission_for_assignment

  # GET /assignments
  # GET /assignments.json
  def index
    @assignments = Assignment.all

    # Redirect to first assignment page or 
    # new assignment page if there are none

    if @assignments.length > 0
      @URL = course_assignment_url(@course, @assignments.first)
    else
      @URL = { :action => 'new' }
    end

    respond_to do |format|
      format.html { redirect_to(@URL) }
      format.json { render json: @assignments }
    end
  end

  # GET /assignments/1
  # GET /assignments/1.json
  def show
    @assignment = Assignment.find(params[:id])
    @submission = get_submission_for_assignment(@assignment)

    if @submission.nil?
      @submission = Submission.new
      @submission.assignment = @assignment
    end

    if current_user.instructor?(@course)
      redirect_to(edit_course_assignment_url(@course, @assignment))
      return
    end

    respond_to do |format|
      format.html
      format.json { render json: @assignment }
    end
  end

  # GET /assignments/new
  # GET /assignments/new.json
  def new
    @assignment = Assignment.new
    @assignment.name = "New Assignment"
    @assignment.reviews_required = 4
    @assignment.draft = true

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @assignment }
    end
  end

  # GET /assignments/1/edit
  def edit
    @assignment = Assignment.find(params[:id])
  end

  # POST /assignments
  # POST /assignments.json
  def create
    @assignment = Assignment.new(params[:assignment])
    @assignment.course_id = @course.id

    respond_to do |format|
      if @assignment.save
        format.html { redirect_to [@course, @assignment], notice: 'Assignment was successfully created.' }
        format.json { render json: @assignment, status: :created, location: @assignment }
      else
        format.html { render action: "new" }
        format.json { render json: @assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /assignments/1
  # PUT /assignments/1.json
  def update
    @assignment = Assignment.find(params[:id])

    respond_to do |format|
      if @assignment.update_attributes(params[:assignment])
        format.html { redirect_to @assignment, notice: 'Assignment was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @assignment.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /assignments/1
  # DELETE /assignments/1.json
  def destroy
    @assignment = Assignment.find(params[:id])
    @assignment.destroy

    respond_to do |format|
      format.html { redirect_to assignments_url }
      format.json { head :no_content }
    end
  end

  def get_course
    if params[:course_id]
      @course = Course.find(params[:course_id])
    end
  end

  def get_submission_for_assignment(assignment)
    @submission = Submission.where(:assignment_id => assignment.id, :user_id => current_user.id)
    return @submission[0]
  end
end
