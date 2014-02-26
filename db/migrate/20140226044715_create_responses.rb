class CreateResponses < ActiveRecord::Migration
  def change
    create_table :responses do |t|
      t.text :peer_review
      t.text :student_response
      t.text :instructor_response
      t.integer :evaluation_id
      t.integer :question_id
      t.integer :scale_id

      t.timestamps
    end
  end
end
