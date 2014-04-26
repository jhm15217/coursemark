class UsersController < ApplicationController
	skip_before_filter :require_login, :except => :edit
	layout false, :except => :edit
	load_and_authorize_resource
	
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
		      format.html # new.html.erb
		      format.json { render json: @user }
		    end
		end
	end  

	def edit
    	@user = current_user
    	@course = @user.courses.first
    	@registrations = current_user.registrations

    	if params[:course]
      		@course = Course.find(params[:course])
      		@assignments = @course.assignments.published
      	end
  	end

	def create  
		@user = User.new(params[:user])  
		if @user.save  
			if !params['course'].blank?
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
			else 
				redirect_to new_registration_url  
			end
		else  
			render :action => 'new'  
		end  
	end

	def update
    @user = User.find(params[:id])

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
end