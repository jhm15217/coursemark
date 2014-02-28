class ChangeDataTypeForSubmission < ActiveRecord::Migration
  def up
  	change_column :submissions, :submission, :string
  end

  def down
  	change_column :submissions, :submission, :binary
  end
end
