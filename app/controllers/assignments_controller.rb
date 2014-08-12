class AssignmentsController < ApplicationController
  require 'csv'
  before_filter :get_course
  load_and_authorize_resource :except => [:new, :create]
  skip_authorization_check :only => [:new, :create]

  # GET /assignments
  # GET /assignments.json
  def index
    @URL = edit_user_path(current_user, :course => @course.id)     #default is settings page
    if @assignment = @course.assignments.last
      @URL = course_assignment_url(@course, @assignment)  # show most recent
      unless current_user.instructor?(@course)
        if urgent = @course.to_do(current_user)[0]   # see if student has a to_do
          @URL = course_assignment_url(@course, urgent[:assignment])
        end
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
    if current_user.instructor?(@course)
      redirect_to(edit_course_assignment_url(@course, @assignment))
      return
    end

    #Create 'To Do' List
    @to_do = @course.to_do(current_user)

    @reviewing_tasks = @assignment.evaluations.forUser(current_user).sort_by{|t| t.created_at}
    @submission = @assignment.get_submission(current_user)
    @questions = @assignment.questions.sort_by{|q| q.created_at }


    if @submission.nil?
      @submission = Submission.new
      @submission.assignment = @assignment
    else
      @evaluations = Evaluation.where(submission_id: @submission.id)
    end

    respond_to do |format|
      format.html
      format.json {render json: @assignment }
    end
  end

  # GET /assignments/new
  # GET /assignments/new.json
  def new
    if !current_user.instructor?(@course)
      return
    end

    @assignment = Assignment.new
    @assignment.name = "New Assignment"
    @assignment.reviews_required = 4

    if @course.get_students.length <= 4
      @assignment.reviews_required = @course.get_students.length - 1
    end

    if @assignment.reviews_required <= 0
      @assignment.reviews_required = 0
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @assignment }
    end
  end

  def export
    @assignment = Assignment.find(params[:assignment_id])
    current_date = "#{Time.now.month}-#{Time.now.day}-#{Time.now.year}"
    send_data(@assignment.export(sorted(@assignment.get_students_for_assignment)), :type => 'text/csv', :filename => "#{@assignment.course.name}: #{@assignment.name} (as of #{current_date}).csv")
  end

  # GET /assignments/1/edit
  def edit
    @reviewing_tasks = @assignment.evaluations.forUser(current_user).sort_by{|e| e.created_at}
    unless @assignment.manual_assignment
      @assignment.reviewers_assigned = true
    end
  end

  # POST /assignments
  # POST /assignments.json
  def create
    if !current_user.instructor?(@course)
      return
    end

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
        format.html { redirect_to [@course, @assignment] }
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
    @reviewing_tasks = @assignment.evaluations.forUser(current_user).sort_by{|e| e.created_at}
    @URL = course_assignment_path(@course, @assignment)

    unless @assignment.team
      @assignment.memberships.each{|m| m.destroy }
    end

    if params['publish']
      if @assignment.draft
        if @assignment.questions.length == 0
          flash[:error] = 'You must first create a rubric.'
          @assignment.draft = true
        else
          @assignment.draft = false
          @URL = edit_course_assignment_path(@assignment.course, @assignment)
        end
      else
        if @assignment.submissions.length != 0
          flash[:error] = 'You must first (somehow) delete all submissions'
          @assignment.draft = false
        else
          @assignment.draft = true
        end
      end
    end

    respond_to do |format|
      if @assignment.update_attributes(params[:assignment])
        format.html { redirect_to @URL }
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
    @assignment.memberships.each{|m| m.destroy }
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

end
