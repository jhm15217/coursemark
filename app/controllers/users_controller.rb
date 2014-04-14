class UsersController < ApplicationController
	skip_before_filter :require_login, :except => :edit
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
end