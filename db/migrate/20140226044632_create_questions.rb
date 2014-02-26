class CreateQuestions < ActiveRecord::Migration
  def change
    create_table :questions do |t|
      t.text :question_text
      t.integer :question_weight
      t.boolean :written_response_required
      t.integer :assignment_id

      t.timestamps
    end
  end
end
