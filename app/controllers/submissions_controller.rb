class SubmissionsController < ApplicationController
  require 'zlib'
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

    registrations =  @course.registrations
    @students = registrations.select{|r| !r.user.pseudo or @assignment.memberships.any?{|m| m.pseudo_user_id == r.user_id }  }.map{|r| r.user }
    #.sort_by{|r| (r.section || "\177") + r.last_name + ' ' + r.first_name }.map{|r| r.user }

    # # Avoid sort if nothing has changed
    # sortable = registrations.map { |r|  { registration: r, sort_key: key(r) } }
    # current_hash = Zlib.crc32(sort_direction + current_user.email +
    #                               sortable.map{|record| record[:registration].id.to_s + record[:sort_key]}.reduce(:+))
    # if current_hash == @assignment.sort_hash
    #   @students = @assignment.cached_sort.map{|r_id| Registration.find(r_id).user }
    # else
    #   sortable.sort! do |a,b|
    #     result = a[:sort_key] <=> b[:sort_key]
    #     sort_direction == 'desc' ? - result : result
    #   end
    #   @assignment.sort_hash = current_hash
    #   @assignment.cached_sort =  sortable.map{|record| record[:registration].id }
    #   @assignment.save!
    #   @students = sortable.map{|record| record[:registration].user }
    # end
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
    @submitter =  @submission.user_id == @user.submitting_id(@submission)

    if params[:instructor_approved_toggle]
      @submission.instructor_approved = !@submission.instructor_approved
      @submission.save!
      if @submission.instructor_approved
        redirect_to  (course_assignment_path({id: params[:assignment_id]} )) + '/submissions'
        return
      else
        respond_to do |format|
          format.html { render :layout => 'no_sidebar' }
          format.json { render json: @submission }
        end
        return
      end
    elsif params[:finish]
      if evaluation.finished    # The reviewer is withdrawing the review
        evaluation.finished = false
        evaluation.save!
        redirect_to  :back
        return
      else
        if evaluation.mark_incomplete_questions
          evaluation.finished = true
          evaluation.save!
          redirect_to  course_assignment_path ({id: params[:assignment_id]} )
          return
        else
          flash[:error] = "You can't publish unless all ratings and required comments are finished."
          redirect_to course_assignment_submission_path ({id: params[:id]} )
          # render 'show', :layout => 'no_sidebar'
          return
        end
      end
    else # it's a student who submitted it or is completing  or seeing a review of someone else
      @kibitzing = params[:instructor]
      respond_to do |format|
        format.html { render (params[:instructor_review_of] ? 'show_review' : 'show'), :layout => 'no_sidebar' }
        format.json { render json: @submission }
      end
      return
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

end
