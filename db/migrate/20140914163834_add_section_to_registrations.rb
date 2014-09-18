class AddSectionToRegistrations < ActiveRecord::Migration
  def change
    add_column :registrations, :section, :string
  end
end
