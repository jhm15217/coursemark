class AddPseudoToUser < ActiveRecord::Migration
  def change
    add_column :users, :pseudo, :boolean
  end
end
