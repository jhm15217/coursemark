require 'test_helper'

class CourseTest < ActiveSupport::TestCase
  # matchers
  should have_many(:assignments)
  should have_many(:registrations)

  should have_many(:users).through(:registrations)

end
