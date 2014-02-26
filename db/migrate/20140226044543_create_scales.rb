class CreateScales < ActiveRecord::Migration
  def change
    create_table :scales do |t|
      t.integer :value
      t.text :description
      t.integer :question_id

      t.timestamps
    end
  end
end
