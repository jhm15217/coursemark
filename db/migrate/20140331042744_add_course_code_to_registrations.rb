class AddCourseCodeToRegistrations < ActiveRecord::Migration
  def change
    add_column :registrations, :course_code, :string
  end
end
