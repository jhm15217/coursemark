module ApplicationHelper
  def prettifyFloat x
    Float(x)
    i, f = x.to_i, x.to_f
    i == f ? i : f
  rescue ArgumentError
    x
  end

  def prettifyFloat(x, precision = 0)
    ("%.#{precision}f" % x)
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

  def multi_flash(tag, m1, m2)
    if flash[tag]
      flash[tag] << ', ' + m2
    else
      flash[tag] = m1 + m2
    end
  end

  def iff(a,b)
    a ? b : !b
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, { sort: column, direction: direction} , { class: css_class }
  end

end
