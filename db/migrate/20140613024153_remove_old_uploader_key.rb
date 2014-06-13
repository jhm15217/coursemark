class RemoveOldUploaderKey < ActiveRecord::Migration
  def up
  	remove_column :submissions, :submission
  end

  def down
  	add_column :submissions, :submission
  end
end
