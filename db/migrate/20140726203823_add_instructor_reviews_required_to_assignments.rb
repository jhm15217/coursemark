class AddInstructorReviewsRequiredToAssignments < ActiveRecord::Migration
  def change
    add_column :assignments, :instructor_reviews_required, :integer, default: 0
  end
end
