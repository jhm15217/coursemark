class Group < ActiveRecord::Base
  attr_accessible :name
  belongs_to :assignment
  has_many :users
end
