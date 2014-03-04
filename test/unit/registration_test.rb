require 'test_helper'

class RegistrationTest < ActiveSupport::TestCase
  should belong_to(:user)
  should belong_to(:course)

  # instructor tests
  should allow_value(true).for(:instructor)
  should allow_value(false).for(:instructor)
  should_not allow_value(nil).for(:instructor)

  # active tests
  should allow_value(true).for(:active)
  should allow_value(false).for(:active)
  should_not allow_value(nil).for(:active)
end
