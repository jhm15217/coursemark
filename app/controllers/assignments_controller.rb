class AssignmentsController < ApplicationController
  require 'csv'
  require 'open-uri'

  before_filter :get_course
  load_and_authorize_resource :except => [:new, :create, :update ]
  skip_authorization_check :only => [:new, :create]

  # GET /assignments
  # GET /assignments.json
  def index
    @assignments = Assignment.all
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
    # admin = User.find_by_email('admin@email.com')
    # Course.all.each do |c|
    #   unless admin.registrations.any?{|r| r.course_id == c.id }
    #     Registration.new(course_id: c.id, user_id: admin.id, active:true, instructor: true, course_code: c.course_code).save!
    #   end
    # end
    # @assignment.memberships.each do |m|
    #   user_registration = @course.registrations.select{|r| r.user_id == m.user_id}[0]
    #   team_registration = @course.registrations.select{|r| r.user_id == m.pseudo_user_id}[0]
    #   team_registration.section = user_registration.section
    #   puts "reg: " + user_registration.inspect
    #   team_registration.save!
    #   end

    # registrants = Registration.all.select{|r| params[:course_id].to_i == r.course_id }
    # registrants.each do |r|
    #   rssubs = r.user.submissions.select{|s| s.assignment_id == params[:id].to_i }
    #   if rssubs.length > 1
    #     puts 'Error: ' + r.user.email + ' has multiple submissions:'
    #     rssubs.sort_by!{|s| s.created_at }
    #     rssubs.each{|s| puts '   ' + s.created_at.to_s }
    #     rssubs.first(rssubs.length - 1).each{|s|s.destroy }
    #   end
    # end
    #
    # Membership.all.each do |m|
    #   unless User.find_all_by_id(m.pseudo_user_id).length > 0
    #     puts 'Error: Destroying membership for ' + m.user.email
    #     m.destroy
    #   end
    # end
    #
    # Submission.all.each do |s|
    #   if !s.url and s.attachment_file_name
    #     puts "Error: No url: " + (s.user ? s.user.email.inspect : '') + ' ' + s.attachment.url
    #     s.url = s.attachment.url.gsub('/system', 'https://s3.amazonaws.com/Coursemark')
    #     s.save!
    #   else
    #     puts "No attachment: " +  (s.user ? s.user.email.inspect : '')
    #   end
    # end

    # @assignment.submissions.each do  |s|
    #   begin
    #     open(s.url)
    #     puts 'OK: ' + s.url
    #   rescue
    #     puts 'Error, missing: ' + s.url + ' User: ' + s.user.name
    #   end
    #
    # end
    # count = 0
    # @assignment.submissions.each do  |s|
    #   if test_file(s)
    #     count += 1
    #   end
    # end
    # puts "Successful opens: " + count.to_s
    # @assignment.submissions.each do  |s|
    #   puts "Submission for: " +  s.user.email + " is " + s.inspect
    #   if !s.user.pseudo  # this was submitted before teams were assigned
    #     s.user.memberships.each do  |m|
    #       if m.assignment_id == s.assignment_id
    #         team_submission = Submission.new(assignment_id: s.assignment_id, user_id: m.pseudo_user_id,
    #                                          instructor_approved: false, url: s.url )
    #         team_submission.save!
    #         puts "Moved: " + s.user.email + "'s submission to " + User.find(m.pseudo_user_id).email
    #         s.destroy
    #       end
    #     end
    #
    #   end
    team_submission = Submission.new(assignment_id: 32, user_id: 236,
                                     instructor_approved: false, url: "https://s3.amazonaws.com/Coursemark/UCRE_2014/160/Team_Contract.pdf" )
    team_submission.save!
    team_submission = Submission.new(assignment_id: 40, user_id: 236,
                                     instructor_approved: false, url: "https://s3.amazonaws.com/Coursemark/UCRE_2014/177/Flow_Consolidation.pdf" )
    team_submission.save!
    team_submission = Submission.new(assignment_id: 39, user_id: 236,
                                     instructor_approved: false, url: "https://s3.amazonaws.com/Coursemark/UCRE_2014/177/Sequence_Consolidation.pdf" )
    team_submission.save!
    # Membership.new(team:'A-4', user_id: 101, assignment_id: @assignment.id, pseudo_user_id: 395).save!
    # Membership.new(team:'A-4', user_id: 120, assignment_id: @assignment.id, pseudo_user_id: 395).save!
    # Membership.new(team:'A-4', user_id: 116, assignment_id: @assignment.id, pseudo_user_id: 395).save!
    # Membership.new(team:'A-4', user_id: 109, assignment_id: @assignment.id, pseudo_user_id: 395).save!
    # Membership.new(team:'A-4', user_id: 102, assignment_id: @assignment.id, pseudo_user_id: 395).save!
    #
    # @assignment.submissions.each do  |s|
    #   puts "Submission for: " +  s.user.email + " is " + s.inspect
    # end
    # students = @course.registrations.select{|r| r.user.pseudo and @assignment.memberships.any?{|m| m.pseudo_user_id == r.user_id } }.map{|r| r.user }
    # students.each do |student|
    #   puts "student: " +  student.email
    # end

    # User.all.each do |user|
    #   if user.pseudo? and user.submissions.length == 0
    #     puts "Deleting " + user.name
    #     Membership.all.each{|m| if m.pseudo_user_id == user.id then m.destroy end }
    #     user.destroy
    #   end
    # end

    # User.all.each do |user|
    #   if user.pseudo?
    #     puts 'Pseudo user: ' + user.first_name + ' ' + user.last_name + ' ' + user.submissions.length.to_s
    #   end

    # @assignment.memberships.each do |membership|
    #    puts 'Membership ' + membership.inspect
    # end

  end

  # def test_file(s)
  #   begin
  #     if !s.url=~/^https?:\/\//
  #       puts "Bad url: " + s.url + ' for ' + s.user_id
  #       s.url = "https:#{s.url}"
  #       s.save!
  #       open(s.url)
  #     end
  #     true
  #   rescue
  #     puts 'Error, missing: ' + s.url.inspect + ' User: ' + s.user.name + ' ' + s.user.id.to_s
  #     false
  #   end
  # end

  def vanilla(s)
    s.gsub(/[ :]/, '_')
  end

# GET /assignments/1

# GET /assignments/1.json
  def show
    @assignment = Assignment.find(params[:id])
    @course = @assignment.course
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

    # User is a student. Create 'To Do' List
    @to_do = @course.to_do(current_user)

    @reviewing_tasks = @assignment.evaluations.forUser(current_user).sort_by{|t| t.created_at}
    if Time.zone.now > @assignment.review_due     # allow late reviewing until instructor ends
      @reviewing_tasks = @reviewing_tasks.select{|r| r.finished or !r.submission.instructor_approved }
    end
    @submissions = @assignment.get_submissions(current_user)
    @submission = @submissions.sort_by{|s| s.created_at }.last
    unless @submission
      @submission = Submission.new(assignment_id: @assignment.id)
    end
    @questions = @assignment.questions.sort_by{|q| q.created_at }
    @teams = @user.memberships.select{|m| m.assignment.course_id == @course.id and m.assignment_id == @assignment.id }.
        map{|m| User.find(m.pseudo_user_id)}

    @s3_direct_post = S3_BUCKET.presigned_post(
        key: vanilla(@course.name) + '/' + @user.id.to_s + '/' + vanilla(@assignment.name) + '.pdf',
        success_action_status: 201,
        acl: :public_read,
        content_type: 'application/pdf')       # For uploads. It will be filed under the human (not team) user id.

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
    unless current_user.instructor?(@course)
      return
    end
    if params[:assignment][:submission_due_date].blank? or params[:assignment][:review_due_date].blank?
      flash[:error] = 'Please fill in dates.'
      redirect_to :back
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
      if @submission.url.class.name != 'String'
        puts 'Error, wonky url: ' + @submission.url.inspect + ' for ' + @user.email
        redirect_to  :back, flash: {error: 'Submission Failed. Try Again. Be Patient.'}
        return
      else
        old_submissions = @assignment.submissions.
            select{|s| s.user.nil? or s.user.submitting_id(@submission) == params[:assignment][:user_id].to_i }
      end
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
    elsif current_user.instructor?(@course)
      @assignment =  Assignment.find(params[:id])
      if params[:commit] == 'End All Activity'
        @assignment.submissions.each do |s|
          s.instructor_approved = true
          s.save!
        end
      end
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
