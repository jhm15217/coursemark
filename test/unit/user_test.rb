require 'test_helper'

class UserTest < ActiveSupport::TestCase
  should_not allow_value(nil).for(:email)
  should_not allow_value(nil).for(:password)
  should_not allow_value(nil).for(:password_digest)
end
