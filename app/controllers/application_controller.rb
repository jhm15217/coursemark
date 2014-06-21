class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :require_login, :except => [:create ]
  before_filter :get_assignments
  helper_method :current_user
  helper_method :get_submission_for_assignment

  def redirect_to(*args)
    flash.keep
    super
  end

  def get_assignments
    # TODO: This should be a scope or a method in a model
    # Getting the right assignments for the user

    if current_user
      if (current_user.registrations.length == 0)
        redirect_to new_registration_url
        return
      end

      @assignments = []
      @course_id = params[:course_id] || params[:course]

      if @course_id.nil?
        @course_id = params[:id]
      end

      if ['users'].include?(params[:controller])
        @course_id = current_user.courses.first.id
      end

      @registration = Registration.where(:course_id => @course_id, :user_id => current_user.id).first
      if @registration && @registration.instructor
        # if a user is an instructor for course, get drafts
        @assignments = @registration.course.assignments
      elsif @registration
        # otherwise user is a student, get published assignments only
        @assignments = @registration.course.assignments.published
      end
    end
  end

  def get_submission_for_assignment(assignment)
    memberships = assignment.memberships.select{|m| m.user_id == current_user.id}
    if memberships.length == 0
      @submission = Submission.where(:assignment_id => assignment.id, :user_id => current_user.id)
    else # This is a team assignment
      @submission = Submission.where(:assignment_id => assignment.id, :user_id => memberships.first.pseudo_user_id )
    end
    return @submission[0]
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url
  end

  def submitting_user(assignment)
    memberships = assignment.memberships.select{|m| m.user_id == current_user.id}
    if memberships.length == 0
      return current_user
    else # This is a team assignment
      return User.find(memberships.first.pseudo_user_id)
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
    if !current_user
      redirect_to login_url
    end
  end
end
