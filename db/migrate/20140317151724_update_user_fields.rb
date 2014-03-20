class UpdateUserFields < ActiveRecord::Migration
  def up
  	remove_column :users, :password
  	remove_column :users, :password_digest
  	add_column :users, :crypted_password, :string
  	add_column :users, :password_salt, :string
  	add_column :users, :persistence_token, :string
  end

  def down
  	add_column :users, :password, :string
  	add_column :users, :password_digest, :string
  	remove_column :users, :crypted_password
  	remove_column :users, :password_salt
  	remove_column :users, :persistence_token
  end
end
