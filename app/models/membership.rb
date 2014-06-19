class Membership < ActiveRecord::Base
  attr_accessible :assignment_id, :team, :user_id, :pseudo_user_id

  belongs_to :assignment
  belongs_to :user

  def self.find_membership(assignment, user_id, team_name)
    memberships = assignment.memberships.select{|m| m.team == team_name and m.user_id == user_id }
    return membership.length == 0 ? nil : memberships.first
  end
end
