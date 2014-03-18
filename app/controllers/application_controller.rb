class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :get_assignments
  helper_method :current_user

  def get_assignments
    @assignments = Assignment.all
  end

  private  
  def current_user_session  
    return @current_user_session if defined?(@current_user_session)  
    @current_user_session = UserSession.find  
  end  
  
  def current_user  
    @current_user = current_user_session && current_user_session.record  
  end  
end