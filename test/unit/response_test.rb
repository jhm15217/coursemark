require 'test_helper'

class ResponseTest < ActiveSupport::TestCase
  should belong_to(:evaluation)
  should belong_to(:question)
  should belong_to(:scale)

  should_not allow_value(nil).for(:evaluation_id)
  should_not allow_value(nil).for(:question_id)
  should_not allow_value(nil).for(:scale_id)
end
