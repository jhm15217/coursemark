require 'test_helper'

class EvaluationTest < ActiveSupport::TestCase
  # matchers
  should belong_to(:user)
  should belong_to(:submission)

  should have_many(:responses)

  # test IDs
  should validate_numercality_of(:user_id)
	should_not allow_value(3.14159).for(:user_id)
  should_not allow_value(0).for(:user_id)
  should_not allow_value(-1).for(:user_id)

  should validate_numercality of(:submission_id)
	should_not allow_value(3.14159).for(:submission_id)
  should_not allow_value(0).for(:submission_id)
  should_not allow_value(-1).for(:submission_id)

end
