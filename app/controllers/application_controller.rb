class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :get_assignments, :require_login
  helper_method :current_user

  def get_assignments
    # TODO: This should be a scope or a method in a model
    # Getting the right assignments for the user

    if current_user
        @assignments = []
        @course_id = params[:course_id]
        
        if @course_id.nil?
          @course_id = params[:id]
        end
        
        current_user.registrations.where(:course_id => @course_id).each do |registration|
          if registration.instructor
            # if a user is an instructor for course, get drafts
            @assignments.concat(registration.course.assignments)
          else
            # otherwise user is a student, get published assignments only
            @assignments.concat(registration.course.assignments.published)
          end
      end
    end
  end

  private  
  def current_user_session  
    return @current_user_session if defined?(@current_user_session)  
    @current_user_session = UserSession.find  
  end  
  
  def current_user  
    @current_user = current_user_session && current_user_session.record 
  end

  def require_login
    unless current_user
      redirect_to login_url
    end
  end
end