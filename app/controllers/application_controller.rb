class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :require_login, :except => [:create ]
  before_filter :get_assignments
  helper_method :current_user

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

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url
  end

  def submitting_user(assignment)
    User.find(current_user.submitting_id(assignment))
  end

  def iff(a,b)
    a ? b : !b
  end

  def compare_users(a,b)
    !iff(a.pseudo,b.pseudo) ? (a.pseudo ? -1 : 1) :
        a.last_name != b.last_name ? a.last_name <=> b.last_name :
            a.first_name != b.first_name ? a.first_name <=> b.first_name :
                0
  end

  def sorted(users)
    users.sort { |a,b| compare_users(a,b) }
  end

  def login_student
    $PUPPET = User.find(params[:student])
    redirect_to root_url
  end

  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    @current_user = $PUPPET || current_user_session && current_user_session.record
    @current_user
  end

  def require_login
    if !current_user
      redirect_to login_url
    end
  end


end
