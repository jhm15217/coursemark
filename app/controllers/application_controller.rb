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

  def find_registrant(course, email)
    user = User.find_by_email(email)
    if user and course.get_people.any?{|s| s.id == user.id }
      user
    else
      multi_flash(:error, 'Can\'t find ', email)
      nil
    end
  end

  def multi_flash(tag, m1, m2)
    if flash[tag]
      flash[tag] << ', ' + m2
    else
      flash[tag] = m1 + m2
    end
  end

  def submitting_user(assignment, submission)
    User.find(current_user.submitting_id(assignment, submission))
  end

  def iff(a,b)
    a ? b : !b
  end

  def combine(messages)
    !messages ? '' : messages.map{|m| m + ' '}.reduce(:+)
  end



  def compare_users(a,b)
    a.pseudo != b.pseudo ? (a.pseudo ? -1 : 1) :
        a.last_name != b.last_name ? a.last_name <=> b.last_name :
            a.first_name != b.first_name ? a.first_name <=> b.first_name :
                0
  end

  def sorted(users)
    users.sort { |a,b| compare_users(a,b) }
  end

  def login_student
#    $PUPPET = User.find(params[:student])
    redirect_to root_url
  end

  def clean_csv_item(s)
    c = s.strip.gsub('<comma>', ',')
    if c =~ /"(.*)"/
      $1
    else
      c
    end
  end

  def sort_column
    params[:sort]
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

  def key(registration)
    (if sort_column == 'Email'
       registration.email
     elsif sort_column == "Name"
       ''
     elsif sort_column == 'Submitted'
       result = Time.zone.now
       @submissions.each{ |s| if s.user_id == registration.user.id then result =  s.created_at; break end }
       result.strftime('%y%m%d%H%M%S')
     elsif sort_column == 'Grade'
       result = 0
       @submissions.each{ |s| if s.user_id == registration.user.id and (g = s.grade) then result = g; break end }
       result.to_s.rjust(3,"0")
     elsif sort_column == 'ID'
       registration.user.id.to_s.rjust(3,'0')
     else   # Section
       (registration.section || "\177")
     end) + (registration.pseudo ? '0' : registration.instructor?(@course) ? '2' : '1') + registration.last_name  + ' ' + registration.first_name

  end




  private

  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    @current_user = current_user_session && current_user_session.record
    @current_user
  end

  def require_login
    if !current_user
      redirect_to login_url
    end
  end



end
