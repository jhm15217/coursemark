class AddFinishedToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :finished, :boolean
  end
end
