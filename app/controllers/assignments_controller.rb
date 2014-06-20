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
    @submission = get_submission_for_assignment(@assignment)
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
    @students = Course.find(@assignment.course_id).get_students.sort_by { |s| s.first_name }.sort_by { |s| s.last_name }
    header_row = ["Name", "Total Points", "Total Possible Points", "Percentage"]
    @assignment.questions.each { |question|
      header_row << question.question_text
      header_row << "Possible Points"
      @assignment.reviews_required.times { |index|
        header_row << "Reviewer #{index+1}"
      }
    }
    header_row << "Reviews Finished"
    header_row << "Reviews Required"
    assignment_csv = CSV.generate do |csv|
      csv << header_row
      @students.each do |student|
        submission = @assignment.submissions.select { |sub| sub.user.id == student.id }
        puts submission.inspect
        submission = submission.length == 0 ? nil : submission[0]
        if submission then
          if !submission.percentage.blank? then
            percent = submission.percentage.round
          else
            percent = ""
          end
          this_sub = [student.name, submission.raw, @assignment.totalPoints, percent]
          # for each of the questions in the assignment
          submission.evaluations[0].responses.sort_by { |obj| obj.created_at }.uniq { |x| x.question_id }.each do |res|

            points_for_q = []

            # get responses for a student's submission
            get_evaluations_for_submission_question(submission, res.question).each_with_index do |response, index|
              if response.is_complete?
                points = (((100 / (response.question.scales.length - 1.0) * response.scale.value)) / 100) * res.question.question_weight
                #points = (response.question.question_weight / (response.question.scales.length - 1.0) * response.scale.value)
                points_for_q << points
              end
            end
            # average points someone got for question
            this_sub << (points_for_q.inject(:+).to_f / points_for_q.length) #.inject{ |sum, el| sum + el }.to_f / points_for_q.size

            # total possible points
            this_sub << res.question.question_weight

            # for each peer response, record their grade of the assignment
            points_for_q.each do |point|
              this_sub << point
            end
          end
        else
          this_sub = [student.name, 0, @assignment.totalPoints, 0] + ([0, 0] + [0]*@assignment.reviews_required)*@assignment.questions.length
        end

        this_sub << @assignment.evaluations.forUser(student).select { |evaluation| evaluation.is_complete? }.length
        this_sub << @assignment.evaluations.forUser(student).length

        csv << this_sub
      end
    end

    current_date = "#{Time.now.month}-#{Time.now.day}-#{Time.now.year}"
    send_data(assignment_csv, :type => 'text/csv', :filename => "#{@assignment.course.name}: #{@assignment.name} (as of #{current_date}).csv")
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

  # GET /assignments/1/edit
  def edit
    @assignment = Assignment.find(params[:id])
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
      if @assignment.questions.length == 0
        flash[:error] = 'You must first create a rubric'
        @url = edit_course_assignment_path(@assignment.course, @assignment)
      else
        @assignment.draft = false
      end
    end

    if params['group']
      CSV.foreach('/Users/jhm/Desktop/' + params['group']['attachment']) do |row|
        team_name = row[3]
        student = User.find_all_by_last_name(row[0]).select{|x| x.first_name == row[1]}[0]
        puts "student: " + student.inspect
        memberships = @assignment.memberships.select{|m| m.team == team_name and m.user_id == student.id }
        membership = memberships.length == 0 ? nil : memberships.first
        #membership = Membership.find(@assignment, student.id, team_name)
        puts "membership: " + membership.inspect
        if !membership then
          # create new pseudo-user
          pseudo_users = User.find_all_by_last_name("Team").select{|x| x.first_name == team_name}
          if pseudo_users.length > 0
            pseudo_user = pseudo_users.first
          else
            pseudo_user = User.new(first_name: team_name, last_name: "Team", pseudo: true)
            pseudo_user.save!(validate: false)
            register_pseudo_user(@course.id, pseudo_user)
            puts "registration"
          end
          puts "pseudo_user: " + pseudo_user.inspect
          membership = Membership.new(team:team_name, user_id: student.id, assignment_id: @assignment.id, pseudo_user_id: pseudo_user.id)
          membership.save!
        else
          membership = memberships[0]
        end
      end
      puts 'Membership: ' +  Membership.all.inspect
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

  def register_pseudo_user(course_id,user)
    registration = Registration.new()
    registration.active = true
    registration.instructor = false
    registration.course_id = course_id
    registration.user = user
    # Throw an error if the user is already registered.
    if (Registration.where(:user_id => user.id).length > 0)
      raise ExistingRegistration
    end
    registration.save!
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

  def get_evaluations_for_submission_question(submission, question)
    rspns = []
    evaluations = Evaluation.where(submission_id: submission)
    evaluations.each do |eval|
      eval.responses.each do |resp|
        if resp.question == question then
          rspns << resp
        end
      end
    end
    return rspns
  end

end
