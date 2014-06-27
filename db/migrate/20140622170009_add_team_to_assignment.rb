class AddTeamToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :team, :boolean, default: false
  end
end
