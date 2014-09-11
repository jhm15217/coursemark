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
      elsif (any = @course.assignments.select{|a| !a.draft }).length > 0
        @URL = course_assignment_path(@course, any.sort_by{|a| a.created_at }.last )     #show newest assignment
      else
        @URL = edit_user_path(current_user)     #go to settings page
      end
    end

    respond_to do |format|
      format.html { redirect_to(@URL) }
      format.json { render json: @assignments }
    end
  end

  def fix
    registrants = Registration.all.select{|r| params[:course_id].to_i == r.course_id }
    registrants.each do |r|
      rssubs = r.user.submissions.select{|s| s.assignment_id == params[:id].to_i }
      if rssubs.length > 1
        puts 'Error: ' + r.user.email + ' has multiple submissions:'
        rssubs.sort_by!{|s| s.created_at }
        rssubs.each{|s| puts '   ' + s.created_at.to_s }
        rssubs.first(rssubs.length - 1).each{|s|s.destroy }
      end
    end

    Membership.all.each do |m|
      unless User.find_all_by_id(m.pseudo_user_id).length > 0
        puts 'Destroying membership for ' + m.user.email
        m.destroy
      end
    end
    Submission.all.each do |s|
      if s.attachment
        puts "Has attachement: " + (s.user ? s.user.email.inspect : '') + ' ' + s.attachment.url
        s.url = s.attachment.url.gsub('/system', 'https://s3.amazonaws.com/Coursemark')
        s.save!
      else
        puts "No attachment: " +  (s.user ? s.user.email.inspect : '')
      end
    end
  end

  def vanilla(s)
    s.gsub(/[ :]/, '_')
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
    @submission = @submissions.sort_by{|s| s.created_at }.last
    unless @submission
      @submission = Submission.new(assignment_id: @assignment.id)
    end
    @questions = @assignment.questions.sort_by{|q| q.created_at }
    @teams = @user.memberships.select{|m| m.assignment.course_id == @course.id and m.assignment_id == @assignment.id }.
        map{|m| User.find(m.pseudo_user_id)}

    @s3_direct_post = S3_BUCKET.presigned_post(
        key: vanilla(@course.name) + '/' + @user.submitting_id(@assignment, @submission).to_s + '/' + vanilla(@assignment.name) + '.pdf',
        success_action_status: 201,
        acl: :public_read,
        content_type: 'application/pdf')       # For uploads

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
    current_date = "#{Time.zone.now.month}-#{Time.zone.now.day}-#{Time.zone.now.year}"
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
    if params[:assignment][:url]   # The user uploaded a file
      if params[:assignment][:user_id] == '-1'
        redirect_to :back, flash: {error: "Please select the team you are submitting for."}
        return
      end
      @user = User.find(params[:assignment][:user_id])
      @assignment = Assignment.find(params[:assignment][:assignment_id])
      @submission = Submission.new(params['assignment'])
      @submission[:url] =  @submission[:url].gsub('//s3.amazonaws.com', 'https://s3.amazonaws.com/Coursemark')
      old_submissions = @assignment.submissions.
          select{|s| s.user.nil? or s.user.submitting_id(@assignment,@submission) == params[:assignment][:user_id].to_i }

      respond_to do |format|
        if @submission.save
          old_submissions.each{|s| s.destroy }
          format.html { redirect_to :back }
          format.json { head :no_content }
        else
          format.html { redirect_to :back, flash: {error: combine(@submission.errors.messages[:url])} }
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
