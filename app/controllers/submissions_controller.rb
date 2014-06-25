class SubmissionsController < ApplicationController
  before_filter :get_assignment, :get_course
  before_filter :get_evaluations, :only => :show
  load_and_authorize_resource :except => [:view]
  skip_authorization_check :only => [:view]

  # GET /submissions
  # GET /submissions.json
  def index
    if !current_user.instructor?(@course)
      raise CanCan::AccessDenied.new("Not authorized!")
    end

    @submissions = @assignment.submissions
    @students =  sorted(@assignment.get_students_for_assignment)  # @assignment version culls pseudo_users not used in this assignment

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
    evaluation = @evaluations.where(:user_id => current_user.id)[0]
    @responses = @evaluations[0].responses.sort_by {|obj| puts "response created at" + obj.created_at.to_s + "xxx"; obj.created_at }

    if params[:finish]
      if evaluation.is_complete?
        evaluation.finished = true
        evaluation.save!
        redirect_to  course_assignment_path ({id: params[:assignment_id]} ) and return
      else
        flash[:error] = "Please answer all the questions."
        redirect_to :back and return
        return
      end
    end

    respond_to do |format|
      format.html { render :layout => 'no_sidebar' } # show.html.erb
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

    respond_to do |format|
      if @submission.save
        format.html { redirect_to [@course, @submission.assignment] }
        format.json { render json: @submission, status: :created, location: @submission }
      else
        puts @submission.errors.full_messages
        format.html { redirect_to [@course, @assignment], flash: {error: "Store of submission failed!"} }
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
        puts @submission.errors.full_messages
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
