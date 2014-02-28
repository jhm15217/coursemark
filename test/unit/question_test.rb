require 'test_helper'

class QuestionTest < ActiveSupport::TestCase
  # matchers
  should belong_to(:assignment)

  should have_many(:responses)
  should have_many(:scales)

  # test IDs
  should validate_numericality_of(:assignment_id)
	should_not allow_value(3.14159).for(:assignment_id)
  should_not allow_value(0).for(:assignment_id)
  should_not allow_value(-1).for(:assignment_id)

  # question weight tests
  should validate_numericality_of(:question_weight)

  # written response required tests
  should allow_value(true).for(:written_response_required)
  should allow_value(false).for(:written_response_required)
  should_not allow_value(nil).for(:written_response_required)

end
