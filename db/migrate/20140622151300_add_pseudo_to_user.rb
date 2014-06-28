class AddPseudoToUser < ActiveRecord::Migration
  def change
    add_column :users, :pseudo, :boolean, default: false
  end
end
