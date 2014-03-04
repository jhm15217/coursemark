require 'test_helper'

class SubmissionTest < ActiveSupport::TestCase
  should belong_to(:assignment)
  should belong_to(:user)

  should_not allow_value(nil).for(:assignment_id)
  should_not allow_value(nil).for(:user_id)
end
