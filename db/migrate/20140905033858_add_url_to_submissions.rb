class AddUrlToSubmissions < ActiveRecord::Migration
  def up
    add_column :submissions, :url, :string
  end

end
