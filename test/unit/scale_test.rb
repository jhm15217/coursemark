require 'test_helper'

class ScaleTest < ActiveSupport::TestCase
  should belong_to(:question)

  should_not allow_value(nil).for(:question_id)
end
