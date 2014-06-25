class AddTeamToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :team, :boolean
  end
end
