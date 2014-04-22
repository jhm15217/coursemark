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
    
    can :edit, User do |u|
      u.id == user.id
    end
    
    can :index, Registration do |r|
      r.user_id == user.id
    end

    can :destroy, Registration do |r|
      r.user_id == user.id
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
      c.get_instructors.include? user
    end

    can :manage, Assignment do |a|
      if a.course
        a.course.get_instructors.include? user
      else
        true
      end
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
        s.assignment.course.get_instructors.include? user
      else
        true
      end
    end

    can :manage, Response do |r|
      if r.evaluation.submission.assignment.course  
        r.evaluation.submission.assignment.course.get_instructors.include? user  
      else
        true
      end
    end

    # student
    can :index, Course do |c|
      c.get_students.include? user
    end

    can :show, Course do |c|
      c.get_students.include? user
    end

    can :index, Assignment do |a|
      a.course.get_students.include? user
    end

    can :show, Assignment do |a|
      (a.course.get_students.include? user) && (!a.draft)
    end

    can :create, Submission do|s|
      if s.assignment.course
        s.assignment.course.get_students.include? user
      else
        true
      end
    end

    can :show, Submission do |s|
      s.user_id == user.id
    end
  end
end
