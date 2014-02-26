class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.datetime :submission_due
      t.datetime :review_due
      t.integer :reviews_required
      t.boolean :draft
      t.integer :course_id

      t.timestamps
    end
  end
end
