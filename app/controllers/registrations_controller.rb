class RegistrationsController < ApplicationController
  skip_before_filter :get_assignments, :except => [:index]
  skip_before_filter :get_submission_for_assignment, :except => [:index]
  layout false, :except => :index

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
    if params[:course]
      @course = Course.find(params[:course])
      @assignments = @course.assignments
      @registrations = @course.registrations.where(:active => true).sort_by{ |r| r.instructor ? 0 : 1 }
      @template = "registrations/roster"
    else
      @registrations = current_user.registrations.where(:active => true).sort_by{ |r| r.instructor ? 0 : 1 }
      @course = current_user.courses.first
      @assignments = @course.assignments
      @template = "registrations/index"
    end

    respond_to do |format|
      format.html { render :template => @template } # index.html.erb
      format.json { render json: @registrations }
    end
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
      format.html # new.html.erb
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

  # POST /registrations
  # POST /registrations.json
  def create
    @registration = Registration.new(params[:registration])
    @registration.active = true;
    @registration.instructor = false;
    @registration.user = current_user

    # Throw an error if the course isnt found.
    @registration.course = Course.where(:course_code => @registration.course_code).first or raise InvalidCourse

    # Throw an error if the user is already registered.
    @existing = Registration.where(:course_code => @registration.course_code, :user_id => current_user.id)
    if (@existing.length > 0)
      raise ExistingRegistration
    end

    respond_to do |format|
      if @registration.save
        format.html { redirect_to root_url }
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
    @registration.active = false;

    if @registration.user_id != current_user.id
      @redirectPath = :back
    else 
      @redirectPath = registrations_url
    end

    @registration.save!

    respond_to do |format|
      format.html { redirect_to @redirectPath }
      format.json { head :no_content }
    end
  end

  def invalidCourse(exception)
    flash[:notice] = 'Invalid course code'
    redirect_to :action => "new"
  end

  def existingRegistration(exception)
    flash[:notice] = 'Already registered for this course'
    redirect_to :action => "new"
  end
end
