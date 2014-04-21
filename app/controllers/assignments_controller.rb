class AssignmentsController < ApplicationController
  require 'csv'
  before_filter :get_course
  helper_method :get_submission_for_assignment
  load_and_authorize_resource

  # GET /assignments
  # GET /assignments.json
  def index
    @assignments = Assignment.where(:course_id => @course.id)

    # Redirect to first assignment page or
    # new assignment page if there are none

    if @assignments.length > 0
      if !current_user.instructor?(@course)
        @assignment = @assignments.published.first
      else
        @assignment = @assignments.first
      end

      if @assignment.nil?
        @URL = edit_user_path(current_user, :course => @course.id)
      else
        @URL = course_assignment_url(@course, @assignments.first)
      end
    else
      if current_user.instructor?(@course)
        @URL = { :action => 'new' }
      else
        @URL = edit_user_path(current_user, :course => @course.id)
      end
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
    # @reviewing_tasks = @assignment.evaluations.forUser(current_user)
    @reviewing_tasks = reviews_for_user_to_complete(@assignment, current_user)

    if @submission.nil?
      @submission = Submission.new
      @submission.assignment = @assignment
    else
      @evaluations = Evaluation.where(submission_id: @submission.id)
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

  # get /assignments/1/export
  def export
    @assignment = Assignment.find(params[:assignment_id])
    #@students = Course.find(@assignment.course_id).get_students

    assignment_csv = CSV.generate do |csv|
      csv << ["Name", "Points", "Possible", "Percentage"]
      @assignment.submissions.each do |submission|
        if !submission.percentage.blank? then 
          percent = submission.percentage.round 
        else 
          percent = "" 
        end
        csv << [submission.user.name, submission.raw, @assignment.totalPoints, percent]
      end
    end

    current_date = "#{Time.now.month}-#{Time.now.day}-#{Time.now.year}"
    send_data(assignment_csv, :type => 'text/csv', :filename => "#{@assignment.course.name}: #{@assignment.name} (as of #{current_date})")
  end

  # GET /assignments/new
  # GET /assignments/new.json
  def new
    @assignment = Assignment.new
    @assignment.name = "New Assignment"
    @assignment.reviews_required = 4

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @assignment }
    end
  end

  # GET /assignments/1/edit
  def edit
    @assignment = Assignment.find(params[:id])
  end

  def publish
    @assignment = Assignment.find(params[:assignment])

    if current_user.instructor?(@assignment.course)
      @assignment.draft = false;
      @assignment.save!
    end

    redirect_to :back
  end

  # POST /assignments
  # POST /assignments.json
  def create
    if params['assignment']['submission_due_time(4i)']
      params['assignment']['submission_due_time'] = params['assignment']['submission_due_time(4i)'] + ':' + params['assignment']['submission_due_time(5i)']
      params['assignment'].delete 'submission_due_time(1i)'
      params['assignment'].delete 'submission_due_time(5i)'
      params['assignment'].delete 'submission_due_time(2i)'
      params['assignment'].delete 'submission_due_time(3i)'
      params['assignment'].delete 'submission_due_time(4i)'
      params['assignment'].delete 'submission_due_time(5i)'
    end

    if params['assignment']['review_due_time(4i)']
      params['assignment']['review_due_time'] = params['assignment']['review_due_time(4i)'] + ':' + params['assignment']['review_due_time(5i)']
      params['assignment'].delete 'review_due_time(1i)'
      params['assignment'].delete 'review_due_time(5i)'
      params['assignment'].delete 'review_due_time(2i)'
      params['assignment'].delete 'review_due_time(3i)'
      params['assignment'].delete 'review_due_time(4i)'
      params['assignment'].delete 'review_due_time(5i)'
    end

    @assignment = Assignment.new(params[:assignment])
    @assignment.course_id = @course.id
    @assignment.draft = true

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
    params['assignment']['submission_due_time'] = params['assignment']['submission_due_time(4i)'] + ':' + params['assignment']['submission_due_time(5i)']
    params['assignment'].delete 'submission_due_time(1i)'
    params['assignment'].delete 'submission_due_time(5i)'
    params['assignment'].delete 'submission_due_time(2i)'
    params['assignment'].delete 'submission_due_time(3i)'
    params['assignment'].delete 'submission_due_time(4i)'
    params['assignment'].delete 'submission_due_time(5i)'

    params['assignment']['review_due_time'] = params['assignment']['review_due_time(4i)'] + ':' + params['assignment']['review_due_time(5i)']
    params['assignment'].delete 'review_due_time(1i)'
    params['assignment'].delete 'review_due_time(5i)'
    params['assignment'].delete 'review_due_time(2i)'
    params['assignment'].delete 'review_due_time(3i)'
    params['assignment'].delete 'review_due_time(4i)'
    params['assignment'].delete 'review_due_time(5i)'

    @assignment = Assignment.find(params[:id])

    respond_to do |format|
      if @assignment.update_attributes(params[:assignment])
        format.html { redirect_to [@course, @assignment], notice: 'Assignment was successfully updated.' }
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
      format.html { redirect_to course_path(@course) }
      format.json { head :no_content }
    end
  end

  def get_course
    if params[:course_id]
      @course = Course.find(params[:course_id])
    end
  end

  def reviews_for_user_to_complete(assignment, current_user) 
    evals = []
    assignment.evaluations.forUser(current_user).each { |eval|  
      complete = eval.responses.all? { |resp| resp.is_complete? }
      if !complete then 
        evals << eval
      end
    }
  end

end
