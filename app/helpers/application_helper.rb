module ApplicationHelper
  def prettifyFloat x
    Float(x)
    i, f = x.to_i, x.to_f
    i == f ? i : f
  rescue ArgumentError
    x
  end

  def prettifyFloat(x, precision = 2)
    x = x.round(1)
    (("%.#{precision}f" % x).split(/\./).last == '0' * precision and x.to_i or x)
  end

  # Takes in a grade (b/w 50-100),
  # returns an associated description
  def gradeColor(grade)
    if grade > 85
      return 'high'
    elsif grade > 70
      return 'mid'
    else
      return 'low'
    end
  end

  # Takes in a grade (b/w 0-100),
  # returns an associated description
  def gradeColorFullScale(grade)
    if grade > 80
      return 'high'
    elsif grade > 60
      return 'mid'
    else
      return 'low'
    end
  end



  def percentage(question, scale)
    scale.value
  end

  def reviewer_name(evaluation, index)
    (evaluation.user.instructor?(evaluation.submission.assignment.course) or
        current_user.instructor?(evaluation.submission.assignment.course)) ? evaluation.user.name :
        'Reviewer ' + (index + 1).to_s
  end

  def multi_flash(tag, m1, m2)
    if flash[tag]
      flash[tag] << ', ' + m2
    else
      flash[:error] = m1 + m2
    end
  end



end
