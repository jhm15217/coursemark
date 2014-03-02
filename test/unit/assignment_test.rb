require 'test_helper'

class AssignmentTest < ActiveSupport::TestCase
  # matchers
  should belong_to(:course)

  should have_many(:submissions)
  should have_many(:questions)

  # date tests
  should allow_value(7.weeks.ago.to_date).for(:submission_due)
  should allow_value(7.weeks.ago.to_date).for(:review_due)

  should allow_value(7.weeks.from_now.to_date).for(:submission_due)
  should allow_value(7.weeks.from_now.to_date).for(:review_due)

  should_not allow_value("bad").for(:submission_due)
  should_not allow_value("bad").for(:review_due)

  should_not allow_value(nil).for(:submission_due)
  should_not allow_value(nil).for(:review_due)

  # tests for reviews required
  should allow_value(1).for(:reviews_required)
  should_not allow_value(0).for(:reviews_required)
  should_not allow_value(-1).for(:reviews_required)
  should_not allow_value("five").for(:reviews_required)

  # tests for draft
  should allow_value(true).for(:draft)
  should allow_value(false).for(:draft)
  should_not allow_value(nil).for(:draft)


end
