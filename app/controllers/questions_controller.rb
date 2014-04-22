class QuestionsController < ApplicationController
  before_filter :get_assignment, :get_course
  load_and_authorize_resource

  # GET /questions
  # GET /questions.json
  def index
    @questions = @assignment.questions

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @questions }
    end
  end

  # GET /questions/1
  # GET /questions/1.json
  def show
    @question = Question.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @question }
    end
  end

  # GET /questions/new
  # GET /questions/new.json
  def new
    @question = Question.new
    @type = params[:type]

    if @type == 'scale'
      @question.scales.build(:value => 0, :description => 'Lowest Score Label')
      @question.scales.build(:value => 1)
      @question.scales.build(:value => 2)
      @question.scales.build(:value => 3)
      @question.scales.build(:value => 4, :description => 'Highest Score Label')
    elsif @type == 'yesno'
      @question.scales.build(:value => 0, :description => 'No')
      @question.scales.build(:value => 1, :description => 'Yes')
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @question }
    end
  end

  # GET /questions/1/edit
  def edit
    @question = Question.find(params[:id])
  end

  # POST /questions
  # POST /questions.json
  def create
    @question = Question.new(params[:question])
    @question.assignment = @assignment

    respond_to do |format|
      if @question.save
        format.html { redirect_to action: "index" }
        format.json { render json: @question, status: :created, location: @question }
      else
        format.html { render action: "new" }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /questions/1
  # PUT /questions/1.json
  def update
    @question = Question.find(params[:id])

    @question.scales do |scale, i|
      scale.value = i+1
      scale.save!
    end 

    respond_to do |format|
      if @question.update_attributes(params[:question])
        format.html { redirect_to action: "index" }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /questions/1
  # DELETE /questions/1.json
  def destroy
    @question = Question.find(params[:id])
    @question.destroy

    respond_to do |format|
      format.html { redirect_to action: "index" }
      format.json { head :no_content }
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
