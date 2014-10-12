class CoursesController < ApplicationController
  skip_before_filter :get_assignments
  layout false
  load_and_authorize_resource

  # GET /courses
  # GET /courses.json
  def index
    puts 'Login: ' + current_user.email
    @courses = current_user.courses
    if @courses.length == 1
      @URL = @courses[0]
    else
      @URL = edit_user_path [current_user]
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
    current_user.registrations.each{|r| if r.course_id == @course.id  then r.active = true; r.save! end }
    Assignment.order(:submission_due)
    @assignments = @course.assignments.select{|a| !a.draft or current_user.instructor?(@course) }

    respond_to do |format|
      if current_user.instructor?(@course)
        format.html { redirect_to course_assignments_path(@course) }
      else
        format.html {render layout: 'application'}
      end
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
      format.html { redirect_to :back }
      format.json { head :no_content }
    end
  end
end
