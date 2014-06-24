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

end
