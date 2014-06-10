class AddColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :confirmed, :boolean
    add_column :users, :confirmation_token, :string
    add_column :users, :password_reset_sent_at, :datetime
    User.reset_column_information
    User.all.each do |p|
       p.update_attribute :confirmed, true
     end
  end
end
