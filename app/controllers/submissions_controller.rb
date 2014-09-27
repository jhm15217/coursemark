class SubmissionsController < ApplicationController
  before_filter :get_assignment, :get_course
  before_filter :get_evaluations, :only => :show
  load_and_authorize_resource
  skip_authorization_check :only => [:update, :create]
  helper_method :sort_column, :sort_direction, :key

  # GET /submissions
  # GET /submissions.json
  def index
    if !current_user.instructor?(@course)
      raise CanCan::AccessDenied.new("Not authorized!")
    end

    @course = Course.find(@assignment.course_id)
    @submissions= @assignment.submissions
    @students =  @assignment.get_participants_in_assignment

    # Avoid sort if nothing has changed
    any_change = @assignment.sort_direction != sort_direction
    @students.each do |s|
      new_key =  key(s)
      if s.sort_key != new_key
        any_change = true
        s.sort_key = new_key
        s.save!(validate: false)
      end
    end
    if any_change
      @assignment.sort_direction = sort_direction
      @assignment.save!
      @students.sort! do |a,b|
        result = a.sort_key <=> b.sort_key
        sort_direction == 'desc' ? - result : result
      end
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @submissions }
    end
  end

  # GET /submissions/1
  # GET /submissions/1.json
  def show
    @submission = Submission.find(params[:id])
    @questions = @submission.assignment.questions.sort_by {|obj| obj.created_at }
    evaluation = @evaluations.where(:user_id => current_user.id).first
    @responses = ((e = @evaluations[0]) ? e.responses.sort_by {|obj| obj.created_at } : [])
    @user = params[:instructor_review_of] ? User.find(params[:instructor_review_of]) : current_user
    @submitter =  @submission.user_id == @user.submitting_id(@assignment, @submission)

    if params[:instructor_approved_toggle]
      @submission.instructor_approved = !@submission.instructor_approved
      @submission.save!
      if @submission.instructor_approved
        redirect_to  (course_assignment_path({id: params[:assignment_id]} )) + '/submissions'
      else
        respond_to do |format|
          format.html { render :layout => 'no_sidebar' }
          format.json { render json: @submission }
        end
      end
    elsif params[:finish]
      if evaluation.finished    # The reviewer is withdrawing the review
        evaluation.finished = false
        evaluation.save!
        redirect_to  :back
      else
        if evaluation.is_complete?
          evaluation.finished = true
          evaluation.save!
          redirect_to  course_assignment_path ({id: params[:assignment_id]} )
        else
          flash[:error] = "You can't publish unless all ratings and required comments have been done."
          redirect_to :back
        end
      end
    else # it's a student who submitted it or is completing  or seeing a review of someone else
      @kibitzing = params[:instructor]
      respond_to do |format|
        format.html { render (params[:instructor_review_of] ? 'show_review' : 'show'), :layout => 'no_sidebar' }
        format.json { render json: @submission }
      end
    end
  end

  # GET /submissions/1
  # GET /submissions/1.json
  def view_reviews
    @submission = Submission.find(params[:id])
    @questions = @submission.assignment.questions.sort_by {|obj| obj.created_at }
    evaluation = @evaluations.where(:user_id => current_user.id)[0]
    @responses = @evaluations[0].responses.sort_by {|obj| obj.created_at }

    respond_to do |format|
      format.html { render view, :layout => 'no_sidebar' } # show.html.erb
      format.json { render json: @submission }
    end
  end

  # def view
  #   @submission = Submission.where(:submission => params[:id].to_s).first
  #   @evaluators = @submission.evaluations.pluck(:user_id)
  #
  #   if (!current_user.instructor?(@submission.assignment.course) && (current_user.id != @submission.user_id) && (!@evaluators.include?(current_user.id)))
  #     raise CanCan::AccessDenied.new("Not authorized!")
  #   end
  #
  #   @filename = 'submission_' + @submission.id.to_s + '.pdf'
  #   send_data(@submission.submission.file.read, :filename => @filename, :disposition => 'inline', :type => 'application/pdf')
  # end

  # GET /submissions/new
  # GET /submissions</a>/new.json
  def new
    @submission = Submission.new
    @submission.instructor_approved = false

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @submission }
    end
  end

  # GET /submissions/1/edit
  def edit
    @submission = Submission.find(params[:id])
  end


  # POST /submissions
  # POST /submissions.json


  def upload_message
    # This is coming from javascript upload activity
    if error = params[:error]
      puts "Error during submission upload for assignment " + Assignment.find(params[:assignment_id]).name + " by "  +
               User.find(params[:user_id]).email  + ': ' + error
    else
      puts "Starting submission upload for assignment " + Assignment.find(params[:assignment_id]).name + " by "  + User.find(params[:user_id]).email
    end
    redirect_to :back
  end

  def create
    if assignment_id = params[:assignment_id]
      # This is coming from javascript upload activity
      if error = params[:error]
        puts "Error during submission upload for assignment " + Assignment.find(assignment_id).name + " by "  + User.find(params[:user_id]).email +
                 " error: " + params[:error].inspect + ' data: ' + params[:data].inspect

      else
        puts "Starting submission upload for assignment " + Assignment.find(assignment_id).name + " by "  + User.find(params[:user_id]).email
      end
      redirect_to :back and return
    end

    @submission = Submission.new(params[:submission])
    respond_to do |format|
      if @submission.save
        format.html { redirect_to [@course, @submission.assignment] }
        format.json { render json: @submission, status: :created, location: @submission }
      else
        format.html { redirect_to [@course, @assignment] , flash: {error: combine(@submission.errors.messages[:url])} }
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end

  end

  # PUT /submissions/1
  # PUT /submissions/1.json
  def update
    @submission = Submission.find(params[:submission])
    respond_to do |format|
      if @submission.update_attributes(params[:submission])
        format.html { redirect_to :back}
      else
        format.html { redirect_to [@course, @assignment] , flash: {error: combine(@submission.errors.messages[:url])} }
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /submissions/1
  # DELETE /submissions/1.json
  def destroy
    @submission = Submission.find(params[:id])
    @submission.destroy

    respond_to do |format|
      format.html { redirect_to submissions_url }
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

  def get_evaluations
    @evaluations = Evaluation.where(submission_id: params[:id])
  end

  private

  def sort_column
    params[:sort]
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

  def key(user)
    (if sort_column == 'Email'
       user.email
     elsif sort_column == "Name"
       ''
     elsif sort_column == 'Submitted'
       result = Time.zone.now
       @submissions.each{ |s| if s.user_id == user.id then result =  s.created_at; break end }
       result.strftime('%y%m%d%H%M%S')
     elsif sort_column == 'Grade'
       result = 0
       @submissions.each{ |s| if s.user_id == user.id and (g = s.grade) then result = g; break end }
       result.to_s
     else   # Section
       (user.registration_in(@course).section || "Z")
     end) + (user.pseudo ? '0' : user.instructor?(@course) ? '2' : '1') + user.last_name  + ' ' + user.first_name
  end

end
