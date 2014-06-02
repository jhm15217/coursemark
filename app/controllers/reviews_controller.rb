class ReviewsController < ApplicationController
  before_filter :get_assignment, :get_course

  def index
  	authorize! :manage, :reviews
  	
    @students = @assignment.course.users.where("instructor = 'f'")

  	respond_to do |format|
      format.html # index.html.erb
    end
  end

  def get_assignment
    if params[:assignment_id]
      @assignment = Assignment.find(params[:assignment_id])
    end
  end

  def get_course
    if params[:course_id]
      @course = Course.find(params[:course_id])
    end
  end
end
