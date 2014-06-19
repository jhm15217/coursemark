class Membership < ActiveRecord::Base
  attr_accessible :assignment_id, :team, :user_id

  belongs_to :assignment
  belongs_to :user
end
