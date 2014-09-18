class AddSortKeyToUser < ActiveRecord::Migration
  def change
    add_column :users,  :sort_key  , :string
  end
end
