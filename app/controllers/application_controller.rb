class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :get_assignments

  def get_assignments
    @assignments = Assignment.all
  end

end