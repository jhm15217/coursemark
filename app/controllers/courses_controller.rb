class CoursesController < ApplicationController
  skip_before_filter :get_assignments
  layout false
  load_and_authorize_resource

  # GET /courses
  # GET /courses.json
  def index

    @courses = current_user.courses

    puts 'Login: ' + current_user.email

    # Redirect to first course page or 
    # new course page if there are none

    if @courses.length > 0
      @URL = @courses.last
    else
      @URL = registrations_path
    end

    respond_to do |format|
      format.html { redirect_to(@URL) }
      format.json { render json: @courses }
    end
  end

  # GET /courses/1
  # GET /courses/1.json
  def show
    @course = Course.find(params[:id])
    @course.registrations.each{|r| (r.active = true; r.save! ) if r.user_id == current_user.id  }


    # Redirect to assignments page

    respond_to do |format|
      format.html { redirect_to course_assignments_path(@course) }
      format.json { render json: @course }
    end
  end

  # GET /courses/new
  # GET /courses/new.json
  def new
    @course = Course.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @course }
    end
  end

  # GET /courses/1/edit
  def edit
    @course = Course.find(params[:id])
  end

  # POST /courses
  # POST /courses.json
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

    @course = Course.new(params[:course])

    respond_to do |format|
      if @course.save
        @registration = Registration.new
        @registration.active = true
        @registration.user = current_user
        @registration.course = @course
        @registration.course_code = @course.course_code
        @registration.instructor = true
        @registration.save!
        admin = User.find_by_email('admin@email.com')
        @registration = Registration.new
        @registration.active = true
        @registration.user = admin
        @registration.course = @course
        @registration.course_code = @course.course_code
        @registration.instructor = true
        @registration.save!

        format.html { redirect_to @course }
        format.json { render json: @course, status: :created, location: @course }
      else
        format.html { render action: "new" }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /courses/1
  # PUT /courses/1.json
  def update
    @course = Course.find(params[:id])

    respond_to do |format|
      if @course.update_attributes(params[:course])
        format.html { redirect_to @course }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /courses/1
  # DELETE /courses/1.json
  def destroy
    @course = Course.find(params[:id])

    @course.destroy

    respond_to do |format|
      format.html { redirect_to courses_url }
      format.json { head :no_content }
    end
  end
end
