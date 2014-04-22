class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :require_login, :get_assignments
  helper_method :current_user
  helper_method :get_submission_for_assignment
  check_authorization

  def get_assignments
    # TODO: This should be a scope or a method in a model
    # Getting the right assignments for the user

    if current_user
      if (current_user.registrations.length == 0)
        redirect_to new_registration_url
        return
      end

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

  def get_submission_for_assignment(assignment)
    @submission = Submission.where(:assignment_id => assignment.id, :user_id => current_user.id)
    return @submission[0]
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
    if !current_user
      redirect_to login_url
    end
  end
end