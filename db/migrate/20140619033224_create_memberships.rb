class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.string :team
      t.integer :user_id
      t.integer :assignment_id

      t.timestamps
    end
  end
end
