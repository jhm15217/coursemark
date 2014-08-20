class SubmissionsController < ApplicationController
  before_filter :get_assignment, :get_course
  before_filter :get_evaluations, :only => :show
  #load_and_authorize_resource :except => [:view]
  skip_authorization_check :only => [:view]

  # GET /submissions
  # GET /submissions.json
  def index
    if !current_user.instructor?(@course)
      raise CanCan::AccessDenied.new("Not authorized!")
    end

    @submissions = @assignment.submissions
    @students =  sorted(@assignment.get_participants_in_assignment)  # @assignment version culls pseudo_users not used in this assignment

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
    @reviewer = params[:instructor_review_of] ? User.find(params[:instructor_review_of]) : current_user


    if params[:instructor]
      respond_to do |format|
        format.html { render :view, :layout => 'no_sidebar' }
        format.json { render json: @submission }
      end
    else
      if params[:finish]
        if evaluation.is_complete?
          evaluation.finished = true
          evaluation.save!
          redirect_to  course_assignment_path ({id: params[:assignment_id]} ) and return
        else
          flash[:error] = "You can't publish unless all ratings and required comments have been done."
          redirect_to :back and return
        end
      end
      respond_to do |format|
        format.html { render :layout => 'no_sidebar' } # show.html.erb
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

  def view
    @submission = Submission.where(:submission => params[:id].to_s).first
    @evaluators = @submission.evaluations.pluck(:user_id)

    if (!current_user.instructor?(@submission.assignment.course) && (current_user.id != @submission.user_id) && (!@evaluators.include?(current_user.id)))
      raise CanCan::AccessDenied.new("Not authorized!")
    end

    @filename = 'submission_' + @submission.id.to_s + '.pdf'
    send_data(@submission.submission.file.read, :filename => @filename, :disposition => 'inline', :type => 'application/pdf')
  end

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
    @submission.user = submitting_user(@assignment)

    @submission.save


    respond_to do |format|
      if @submission.save
        format.html { redirect_to [@course, @submission.assignment] }
        format.json { render json: @submission, status: :created, location: @submission }
      else
        format.html { redirect_to [@course, @assignment] , flash: {error: @submission.errors.messages[:attachment]} }
        format.json { render json: @submission.errors, status: :unprocessable_entity }
      end
    end

  end

  # PUT /submissions/1
  # PUT /submissions/1.json
  def update
    @submission = Submission.find(params[:id])

    respond_to do |format|
      if @submission.update_attributes(params[:submission])
        format.html { redirect_to :back}
      else
        format.html { render action: "edit" }
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

end
