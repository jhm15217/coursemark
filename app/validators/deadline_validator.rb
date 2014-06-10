class DeadlineValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    unless record[attribute].nil?
    	if record[attribute] < Date.today
      		record.errors.add(attribute, "Can't change deadline that's already past")
    	end
    end
  end
end
