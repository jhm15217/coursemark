class CreateRegistrations < ActiveRecord::Migration
  def change
    create_table :registrations do |t|
      t.boolean :instructor
      t.boolean :active
      t.integer :user_id
      t.boolean :course_id

      t.timestamps
    end
  end
end
