class AddFinishedToEvaluations < ActiveRecord::Migration
  def change
    add_column :evaluations, :finished, :boolean, default: false
  end
end
