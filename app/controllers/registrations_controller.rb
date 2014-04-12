class RegistrationsController < ApplicationController
  layout false, :except => :index
  
  # GET /registrations
  # GET /registrations.json
  def index
    if params[:course]
      @course = Course.find(params[:course])
      @registrations = @course.registrations
      @template = "registrations/roster"
    else
      @registrations = current_user.registrations
      @course = current_user.courses.first
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

  # POST /registrations
  # POST /registrations.json
  def create
    @registration = Registration.new(params[:registration])
    @registration.active = true;
    @registration.instructor = false;
    @registration.user = current_user

    # TODO: Throw an error if the course isnt found.
    @registration.course = Course.where(:course_code => @registration.course_code)[0]

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
    @registration.save!

    respond_to do |format|
      format.html { redirect_to registrations_url }
      format.json { head :no_content }
    end
  end
end
