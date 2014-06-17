class RemoveFinishedFromEvaluations < ActiveRecord::Migration
  def up
    remove_column :evaluations, :finished?
  end

  def down
    add_column :evaluations, :finished?, :boolean
  end
end
