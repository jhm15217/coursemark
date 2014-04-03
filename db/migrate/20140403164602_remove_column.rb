class RemoveColumn < ActiveRecord::Migration
  def up
  	remove_column :submissions, :submitted
  end

  def down
  	add_column :submissions, :submitted, :datetime
  end
end
