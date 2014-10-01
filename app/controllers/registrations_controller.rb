class RegistrationsController < ApplicationController
  require 'csv'
  skip_before_filter :get_assignments, :except => [:index]
  load_and_authorize_resource :except => [:add_to_course_staff, :invite_students]
  helper_method :sort_column, :sort_direction, :key

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
    @template = "registrations/roster"

    sortable = @course.registrations.map { |r|  { registration: r, sort_key: key(r) } }
    sortable.sort! do |a,b|
      result = a[:sort_key] <=> b[:sort_key]
      sort_direction == 'desc' ? - result : result
    end
    @registrations = sortable.map{|record| record[:registration] }
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
    params[:response][:invites].split("\r\n").each do |line|
      invite_student(line.split(",").map{|s| clean_csv_item(s)})
    end
    redirect_to :back
  end

  def invite_student(row)     #First Name,Last Name,Email,Section(optional)
    if user = User.find_by_email(row[2].downcase)
      @course.register(user, row[3])
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
        submission.evaluations.each do |evaluation|
          if evaluation.user_id == @registration.user_id
            evaluation.destroy
          end
        end
        if submission.user_id == @registration.user_id
          submission.destroy
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
      format.html { redirect_to registrations_url(course: @course) }
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
