class SubmissionsController < ApplicationController
  before_filter :get_assignment, :get_course
  before_filter :get_evaluations, :only => :show

  # GET /submissions
  # GET /submissions.json
  def index
    @submissions = @assignment.submissions.sort_by{ |s| s.user.last_name }

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @submissions }
    end
  end

  # GET /submissions/1
  # GET /submissions/1.json
  def show
    @submission = Submission.find(params[:id])

    respond_to do |format|
      format.html { render :layout => 'no_sidebar' } # show.html.erb
      format.json { render json: @submission }
    end
  end

  def view
    @submission = Submission.where(:submission => params[:id].to_s).first
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
    puts "ATTEMPTING SAVE 1"
    @submission = Submission.new(params[:submission])
    @submission.user = current_user

    puts "ATTEMPTING SAVE 2"

    respond_to do |format|
      if @submission.save
        puts "SAVED"
        format.html { redirect_to [@course, @assignment] }
        format.json { render json: @submission, status: :created, location: @submission }
      else
        puts "DIDNT SAVE"
        puts @submission.errors
        format.html { redirect_to [@course, @assignment] }
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
        if @submission.instructor_approved
          @submissions = @assignment.submissions.sort_by{ |s| s.user.last_name }
          @submissions.each do |sub|
            if !sub.instructor_approved || sub.instructor_approved.blank?
              @nextSubmission = sub
              break
            end
          end
          if @nextSubmission.blank?
            format.html { redirect_to [@course, @assignment]}
          else
            format.html { redirect_to [@course, @assignment, @nextSubmission]}
          end
        else 
          format.html { redirect_to :back }
          format.json { head :no_content }
        end
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
