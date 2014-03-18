class UsersController < ApplicationController
	layout false 
	
	def new  
		@user = User.new

		respond_to do |format|
	      format.html # new.html.erb
	      format.json { render json: @course }
	    end
	end  

	def edit
    	@user = User.find(params[:id])
  	end

	def create  
		@user = User.new(params[:user])  
		if @user.save  
			flash[:notice] = "Registration successful."  
			redirect_to root_url  
		else  
			render :action => 'new'  
		end  
	end  
end
