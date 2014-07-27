class AssignmentsController < ApplicationController
  require 'csv'
  before_filter :get_course
  helper_method :get_submission_for_assignment
  load_and_authorize_resource :except => [:new, :create]
  skip_authorization_check :only => [:new, :create]

  # GET /assignments
  # GET /assignments.json
  def index
    @assignments = Assignment.where(:course_id => @course.id)

    # Redirect to first assignment page or
    # new assignment page if there are none

    if @assignments.length > 0

      if !current_user.instructor?(@course)
        @assignment = @assignments.published.last
      else
        @assignment = @assignments.last
      end

      if @assignment.nil?
        @URL = edit_user_path(current_user, :course => @course.id)
      else
        @URL = course_assignment_url(@course, @assignment)
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
    if current_user.instructor?(@course)
      redirect_to(edit_course_assignment_url(@course, @assignment))
      return
    end

    @submission = get_submission_for_assignment(@assignment)
    @reviewing_tasks = @assignment.evaluations.forUser(current_user)

    if @submission.nil?
      @submission = Submission.new
      @submission.assignment = @assignment
    else
      @evaluations = Evaluation.where(submission_id: @submission.id)
    end

    respond_to do |format|
      format.html
      format.json { render json: @assignment }
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

    @URL = course_assignment_path(@course, @assignment)

    if params['publish']
      @assignment.draft = false
      if @assignment.questions.length == 0
        flash[:error] = 'You must first create a rubric.'
        @assignment.draft = true
      end
      max_team_size = 1
      if @assignment.team  or params[:assignment][:team] and  params[:assignment][:team] == "1"
        unless @course.get_real_students.all?{|student| @assignment.memberships.sum{|membership| membership.user_id == student.id ? 1 : 0} == 1}
          flash[:error] = "Each student must be a member of one team."
          @assignment.draft = true
        end
        #Figure out max team size
        team_count = Hash.new(0)
        @assignment.memberships.each{|membership| team_count[membership.team] += 1}
        max_team_size = (team_count.values.max or 1)
      end
      # if reviews_required has since become infeasible
      if @course.get_real_students.length - max_team_size < @assignment.reviews_required
        flash[:error] = "At most " + (@course.get_real_students.length - max_team_size).to_s + " reviews can be required."
        @assignment.draft = true
      end

      if !@assignment.draft
        @URL = edit_course_assignment_path(@assignment.course, @assignment)
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
