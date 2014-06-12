class AddManualAssignmentToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :manual_assignment, :boolean
  end
end
