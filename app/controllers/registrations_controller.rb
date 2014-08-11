class RegistrationsController < ApplicationController
  require 'csv'
  skip_before_filter :get_assignments, :except => [:index]
  skip_before_filter :get_submission_for_assignment, :except => [:index]
  load_and_authorize_resource :except => [:add_to_course_staff, :invite_students]

  # Exception Handling
  class InvalidCourse < StandardError
  end
  rescue_from InvalidCourse, :with => :invalidCourse

  class ExistingRegistration < StandardError
  end
  rescue_from ExistingRegistration, :with => :existingRegistration

  # GET /registrations
  # GET /registrations.json
  def index
    @course = params[:course] ? Course.find(params[:course]) :  current_user.courses.last
    @assignments = @course.assignments
    @registrations = sorted_registrations(@course.registrations)
    @template = "registrations/roster"

    respond_to do |format|
      format.html #index.html
      format.json { render json: @registrations }
    end
  end

  def sorted_registrations(r)
    r.sort { |a,b|
      !iff(a.instructor, b.instructor)  ? (a.instructor ? -1 : 1) :
          !iff(a.user.pseudo, b.user.pseudo) ? (a.user.pseudo ? 1 : -1) :
              compare_users(a.user, b.user) }
  end



  # GET /registrations/1
  # GET /registrations/1.json
  def show
    @registration = Registration.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @registration }
    end
  end

  # GET /registrations/new
  # GET /registrations/new.json
  def new
    @registration = Registration.new

    respond_to do |format|
      format.html { render :layout => 'startup_page' }
      format.json { render json: @registration }
    end
  end

  # GET /registrations/1/edit
  def edit
    @registration = Registration.find(params[:id])
  end

  def add_to_course_staff
    @registration = Registration.find(params[:registration])

    if current_user.instructor?(@registration.course)
      @registration.instructor = true
      @registration.save!
    end

    redirect_to :back
  end

  def invite_students
    @course = Course.find(params[:course])
    CSV.foreach('/Users/jhm/Downloads/' + params['invites']['attachment']) do |row|
    invite_student(row)
    end
    redirect_to :back
  end

  def invite_student(row)
    if user = User.find_by_email(row[2])
      unless @course.get_students.any?{|s| s.id == user.id }
        @course.register(user)
        UserMailer.registration_email(user, @course).deliver
      end
    else
      password = SecureRandom.hex(4)
      user = User.new({first_name: row[0], last_name: row[1], email:row[2], password: password, password_confirmation: password})
      user.confirmed = true
      user.save!
      @course.register(user)
      UserMailer.welcome_email(user, password, @course).deliver
    end

  end


  # POST /registrations
  # POST /registrations.json
  def create
    @registration = Registration.new(params[:registration])
    @registration.active = true;
    @registration.instructor = false;
    @registration.user = current_user

    # Throw an error if the course isn't found.
    @registration.course = Course.where(:course_code => @registration.course_code).first or raise InvalidCourse

    # Throw an error if the user is already registered.
    @existing = Registration.where(:course_code => @registration.course_code, :user_id => current_user.id)
    if (@existing.length > 0)
      raise ExistingRegistration
    end

    respond_to do |format|
      if @registration.save
        format.html { redirect_to course_path(@registration.course) }
        format.json { render json: @registration, status: :created, location: @registration }
      else
        format.html { render action: "new" }
        format.json { render json: @registration.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /registrations/1
  # PUT /registrations/1.json
  def update
    @registration = Registration.find(params[:id])

    respond_to do |format|
      if @registration.update_attributes(params[:registration])
        format.html { redirect_to @registration, notice: 'Registration was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @registration.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /registrations/1
  # DELETE /registrations/1.json
  def destroy
    @registration = Registration.find(params[:id])
    @course = @registration.course
    @assignments = @course.assignments

    # Destroy dependent structure first
    @assignments.each do |assignment|
      assignment.submissions.each do |submission|
        if submission.user_id == @registration.user_id
          submission.destroy
        else
          submission.evaluations.each do |evaluation|
            if evaluation.user_id == @registration.user_id
              evaluation.destroy
            end
          end
        end
      end
      assignment.memberships.each do |membership|
        if membership.user_id == @registration.user_id
          membership.destroy
        end
      end
    end
    @registration.destroy

    respond_to do |format|
      format.html { redirect_to registrations_url }
      format.json { head :no_content }
    end
  end

  def invalidCourse(exception)
    flash[:error] = 'There is no course with that code.'
    redirect_to :action => "new"
  end

  def existingRegistration(exception)
    flash[:error] = 'Your are already registered for this course'
    redirect_to :action => "new"
  end
end
