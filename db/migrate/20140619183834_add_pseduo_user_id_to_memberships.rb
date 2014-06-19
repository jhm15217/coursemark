class AddPseduoUserIdToMemberships < ActiveRecord::Migration
  def change
    add_column :memberships, :pseudo_user_id, :integer
  end
end
