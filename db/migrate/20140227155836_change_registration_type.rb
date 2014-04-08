class ChangeRegistrationType < ActiveRecord::Migration
  def up
	connection.execute(%q{
	    alter table registrations
	    alter column course_id
	    type integer using cast(number as integer)
	})
  end

  def down
  	change_column :registrations, :course_id, :boolean
  end
end
