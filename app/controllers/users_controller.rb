class UsersController < ApplicationController
	skip_before_filter :require_login, :except => [:edit, :update]
	# load_and_authorize_resource

  def index
  end

  def all_users
    @course = Course.all[0]
  end

  def destroy
    User.find(params[:id]).destroy
    respond_to do |format|
      format.html { redirect_to :back }
      format.json { head :no_content }
    end

  end

  # GET
  def new
		if current_user
			if !request.GET['course'].blank?
				@registration = Registration.new()
				@registration.active = true;
        @registration.instructor = false;
        @registration.user = @user
        @registration.course_code = params['course']
				@registration.course = Course.where(:course_code => params['course']).first or raise InvalidCourse
					
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
	    else
			@user = User.new

      respond_to do |format|
        format.html { render :layout => 'startup_page' }
        format.json { render json: @course }
      end
		end
	end

  def edit
    @user = current_user
    @course = @user.courses.first
    @registrations = @user.registrations

    if params[:course]
      @course = Course.find(params[:course])
      @assignments = @course.assignments.published
    end
  end

  # POST
  def create
    # Checks if user started to register
    params[:user][:email] =  params[:user][:email].downcase
    if !User.find_by_email(params[:user][:email])
      @user = User.new(params[:user])
      if @user.save
        respond_to do |format|
          # Tell the UserMailer to send a welcome Email after save
          flash[:success] = "Welcome to Coursemark."
          UserMailer.welcome_email_walk_on(@user).deliver
          # UserMailer.delay.welcome_email(@user)
          format.html { redirect_to(email_confirmation_path(id: @user.id)) }
        end
      else
        respond_to do |format|
          format.html { render action: 'new', :layout => 'startup_page', flash: {error: 'Password and/or confirmation is wrong.' }}
        end
      end
    else
      respond_to do |format|
        format.html {
          flash.now[:error] = 'That email has already been registered.'
          render action: 'new', :layout => 'startup_page'}
      end
    end
  end

  def update
    @user = User.find(params[:id])
    @course = @user.courses.last!
    @registrations = current_user.registrations

    respond_to do |format|
      if @user.update_attributes(params[:user])
        format.html { redirect_to edit_user_url, notice: 'Profile was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @response.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET
  # Confirms the email address of a user by matching confirmation token
  def confirm_email
    confirmation_token = params[:confirmation_token]
    @user = User.find_by_id(params[:id])
    if @user.confirmed
      redirect_to root_path, notice: "You already validated your email"
    elsif @user.confirmation_token == confirmation_token
      @user.confirmed = true
      @user.save(validate: false)
      redirect_to login_path, flash: {success: "Your email is confirmed. Please login."}
    else
      redirect_to root_path, flash: { error: "Access denied"}
    end
  end

  # POST
  def resend_confirm_email
    @user = User.find(params[:id])
    UserMailer.welcome_email(@user).deliver
    redirect_to email_confirmation_path(id: @user.id)
  end



end
