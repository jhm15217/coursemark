class SubmissionsController < ApplicationController
  before_filter :get_assignment, :get_course
  before_filter :get_evaluations, :only => :show
  load_and_authorize_resource
  skip_authorization_check :only => [:update]
  helper_method :sort_column, :sort_direction, :key

  # GET /submissions
  # GET /submissions.json
  def index
    if !current_user.instructor?(@course)
      raise CanCan::AccessDenied.new("Not authorized!")
    end

    @submissions= @assignment.submissions
    @students =  @assignment.get_participants_in_assignment.sort do |a,b|
      result = sort_column == 'Name' ? compare_users(a,b) : key(a) <=> key(b)
      sort_direction == 'desc' ? - result : result
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
      if evaluation.is_complete?
        evaluation.finished = true
        evaluation.save!
        redirect_to  course_assignment_path ({id: params[:assignment_id]} )
      else
        flash[:error] = "You can't publish unless all ratings and required comments have been done."
        redirect_to :back
      end
    else # it's a student who submitted it or is completing  or seeing a review of someone else
      respond_to do |format|
        format.html { render 'show', :layout => 'no_sidebar' } # show.html.erb
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
  # GET /submissions/new.json
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
  def create
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
    if sort_column == 'Email'
      user.email
    elsif sort_column == "Section"
      user.registration_in(@course).section || ""
    elsif sort_column == 'Submitted'
      result = Time.zone.now
      @submissions.each{ |s| if s.user_id == user.id then result =  s.created_at; break end }
      result
    elsif sort_column == 'Grade'
      result = 0
      @submissions.each{ |s| if s.user_id == user.id and (g = s.grade) then result = g; break end }
      result
    else
      user.last_name
    end
  end

end
