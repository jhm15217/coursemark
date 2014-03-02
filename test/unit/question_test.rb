require 'test_helper'

class QuestionTest < ActiveSupport::TestCase
  # matchers
  should belong_to(:assignment)

  should have_many(:responses)
  should have_many(:scales)

  # question weight tests
  should validate_numericality_of(:question_weight)
  should allow_value(80).for(:question_weight)
  should_not allow_value(0).for(:question_weight)
  should_not allow_value(-1).for(:question_weight)

  # written response required tests
  should allow_value(true).for(:written_response_required)
  should allow_value(false).for(:written_response_required)
  should_not allow_value(nil).for(:written_response_required)

end
