class Ability
  include CanCan::Ability

  def initialize(user)
 
    # universal
    can :destroy, UserSession
    can :create, UserSession 

    can :new, Course
    can :create, Course

    can :new, User
    can :create, User
    can :confirm_email, User
    can :manage, User do |u|
      if not user
        puts "No user vs. " + u.inspect
      end
      if user && u.id && user.id
        u.id == user.id
      else
        true
      end
    end
    
    can :index, Registration do |r|
      r.user_id == user.id
    end

    can :destroy, Registration do |r|
      (r.user_id == user.id) || (user.instructor?(Course.find(r.course)))
    end

    can :new, Registration do |r|
      if r.user_id
        r.user_id == user.id
      else
        true
      end
    end

    can :create, Registration do |r|
      if r.user_id
        r.user_id == user.id
      else
        true
      end
    end

    # instructor
    can :manage, Course do |c|
      # c.get_instructors.include? user
      user.email == 'admin@emailcom'
    end

    can :manage, Assignment do |a|
      if a.course
        a.course.get_instructors.include? user
      else
        true
      end
    end

    can :manage, :reviews do |r|
      true
    end

    can :manage, Question do |q|
      if q.assignment
        q.assignment.course.get_instructors.include? user
      else
        true
      end
    end

    can :manage, Submission do |s|
      if s.assignment  
        (s.assignment.course.get_instructors.include? user) || (s.user.id == user.submitting_id(s.assignment, s))
      else
        true
      end
    end

    can :manage, Response do |r|
      if r.evaluation.user_id == user.id
        true
      elsif r.evaluation.submission.assignment.course
        r.evaluation.submission.assignment.course.get_instructors.include? user
      else
        true
      end
    end

    can :manage, Evaluation do |e|
      if e.user_id == user.id
        true
      elsif e.submission.assignment.course
        e.submission.assignment.course.get_instructors.include? user
      else
        true
      end
    end

    # student
    can :index, Course do |c|
      c.get_people.include? user
    end

    can :show, Course do |c|
      c.get_people.include? user
    end

    can :index, Assignment do |a|
      a.course.get_people.include? user
    end

    can :show, Assignment do |a|
      (a.course.get_people.include? user) && (!a.draft)
    end

    can :create, Submission do|s|
      if s.assignment.course
        s.assignment.course.get_people.include? user
      else
        true
      end
    end

    can :show, Submission do |s|
      @evaluator = false

      s.evaluations.each do |e|
        if (e.user_id == user.id)
          @evaluator = true
        end
      end

      @evaluator || (s.user_id == user.submitting_id(s.assignment, s))
    end
  end
end
