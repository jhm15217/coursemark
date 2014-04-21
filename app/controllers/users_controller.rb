class UsersController < ApplicationController
	skip_before_filter :require_login, :except => :edit
	load_and_authorize_resource
	layout false, :except => :edit
	
	def new  
		@user = User.new

		respond_to do |format|
	      format.html # new.html.erb
	      format.json { render json: @course }
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
			redirect_to new_registration_url  
		else  
			render :action => 'new'  
		end  
	end

	def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:response])
        format.html { redirect_to edit_user_url, notice: 'Profile was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @response.errors, status: :unprocessable_entity }
      end
    end
  end  
end