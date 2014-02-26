class CreateEvaluations < ActiveRecord::Migration
  def change
    create_table :evaluations do |t|
      t.integer :submission_id
      t.integer :user_id

      t.timestamps
    end
  end
end
