class CreateSubmissions < ActiveRecord::Migration
  def change
    create_table :submissions do |t|
      t.datetime :submitted
      t.binary :submission
      t.integer :assignment_id
      t.integer :user_id

      t.timestamps
    end
  end
end
