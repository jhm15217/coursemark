require 'test_helper'

class EvaluationTest < ActiveSupport::TestCase
  # matchers
  should belong_to(:user)
  should belong_to(:submission)

  should have_many(:responses)

end
