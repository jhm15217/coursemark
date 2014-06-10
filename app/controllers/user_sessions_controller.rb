class UserSessionsController < ApplicationController
	skip_before_filter :require_login
	load_and_authorize_resource
	
	def new
		@user_session = UserSession.new

		respond_to do |format|
	      format.html { render :layout => 'startup_page' }
	      format.json { render json: @course }
	    end
	end

	def create  
		@user_session = UserSession.new(params[:user_session])  
		if @user_session.save  
		  redirect_to root_url
		else  
			render :action => 'new', :layout => 'startup_page'
		end  
	end 

	def destroy  
		@user_session = UserSession.find  
		@user_session.destroy  
		redirect_to root_url  
	end   
end
