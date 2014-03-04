class ChangeRegistrationType < ActiveRecord::Migration
  def up
  	change_column :registrations, :course_id, :integer
  end

  def down
  	change_column :registrations, :course_id, :boolean
  end
end
