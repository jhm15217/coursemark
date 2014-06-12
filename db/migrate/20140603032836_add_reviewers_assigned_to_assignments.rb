class AddReviewersAssignedToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :reviewers_assigned, :boolean
  end
end
