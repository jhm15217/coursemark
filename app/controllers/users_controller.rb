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
    	@user = User.find(params[:id])
    	@course = @user.courses.first
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