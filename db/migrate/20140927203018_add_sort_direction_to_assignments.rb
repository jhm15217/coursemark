class AddSortDirectionToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :sort_direction, :string
  end
end
