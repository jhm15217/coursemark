class AssignmentsController < ApplicationController
  require 'csv'
  before_filter :get_course
  load_and_authorize_resource :except => [:new, :create, :update]
  skip_authorization_check :only => [:new, :create]

  # GET /assignments
  # GET /assignments.json
  def index
    if current_user.instructor?(@course)
      if @assignment = @course.assignments.last
        @URL = course_assignment_url(@course, @assignment)
      else
        @URL = edit_user_path(current_user, :course => @course.id)     #default is settings page
      end
    else  #student
      if urgent = @course.to_do(current_user)[0]   # see if student has a to_do
        @URL = course_assignment_url(@course, urgent[:assignment])
      elsif  pair = @course.assignments.map{|x| x.draft ? nil :
          (Time.zone.now < x.review_due) ? { assignment: x, time: x.review_due } :
              nil }.select{|x| x }.sort_by{|y| y[:time] }[0]
        @URL = course_assignment_url(@course, pair[:assignment]) # show one with open reviews
      else
        @URL = edit_user_path(current_user, :course => @course.id)     #default is settings page

      end
    end

    respond_to do |format|
      format.html { redirect_to(@URL) }
      format.json { render json: @assignments }
    end
  end

  # def switch_names(registration)
  #   if !registration.active
  #     user = registration.user
  #     t = user.first_name
  #     user.first_name = user.last_name
  #     user.last_name = t
  #     user.save!(validate: false)
  #   end
  # end

  def fix
#    Course.find(params[:course_id]).registrations.each{|r| switch_names(r) }
  end

# GET /assignments/1

  # GET /assignments/1.json
  def show
    @assignment = Assignment.find(params[:id])
    @user = current_user
    if @user.instructor?(@course)
      if params[:fix]
        fix
      end
      if reviewer_id = params[:reviewer]
        @reviewer = User.find(reviewer_id)
        @reviewing_tasks = @assignment.evaluations.forUser(@reviewer)
        render 'assignments/show_instructor'
        return
      else
        redirect_to(edit_course_assignment_url(@course, @assignment))
        return
      end
    end

    #Create 'To Do' List
    @to_do = @course.to_do(current_user)

    @reviewing_tasks = @assignment.evaluations.forUser(current_user).sort_by{|t| t.created_at}
    @submissions = @assignment.get_submissions(current_user)
    @submission = @submissions.last
    unless @submission
      @submission = Submission.new(assignment_id: @assignment.id)
    end
    @questions = @assignment.questions.sort_by{|q| q.created_at }
    @teams = @user.memberships.select{|m| m.assignment.course_id == @course.id and m.assignment_id == @assignment.id }.map{|m| User.find(m.pseudo_user_id)}

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

    @assignment.manual_assignment = true
    @assignment.draft = true

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
    @user = User.find(params[:assignment][:user_id])
    if params[:assignment][:attachment]   # The user uploaded a file
      puts "Starting STORE PDF for: "  + @user.name + ' ' + @user.email
      @assignment = Assignment.find(params[:assignment][:assignment_id])
      if params[:assignment][:user_id] == '-1'
        redirect_to :back, flash: {error: "Please select the team you are submitting for."}
        return
      end
      old_submissions = @assignment.submissions.select{|s| s.user_id == params[:assignment][:user_id].to_i }
      @submission = Submission.new(params['assignment'])

      respond_to do |format|
        if @submission.save
          old_submissions.each{|s| s.destroy }
          format.html { redirect_to :back }
          format.json { head :no_content }
        else
          format.html { redirect_to :back, flash: {error: combine(@submission.errors.messages[:attachment])} }
          format.json { render json: @assignment.errors, status: :unprocessable_entity }
        end
      end
    else
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
        params[:assignment][:draft] = @assignment.draft  ? '0' : '1'
      end

      respond_to do |format|
        if @assignment.update_attributes(params[:assignment])
          format.html { render action: "edit" }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @assignment.errors, status: :unprocessable_entity }
        end
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
