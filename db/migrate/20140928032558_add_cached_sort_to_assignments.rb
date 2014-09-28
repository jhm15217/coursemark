class AddCachedSortToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :cached_sort, :string
  end
end
