class AddSortCachingToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :cached_sort, :text
    add_column :assignments, :sort_hash, :integer, limit: 8
  end
end
