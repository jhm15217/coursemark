class AddApprovalToSubmission < ActiveRecord::Migration
  def change
    add_column :submissions, :instructor_approved, :boolean
  end
end
