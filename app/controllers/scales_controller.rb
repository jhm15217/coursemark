class ScalesController < ApplicationController
  before_filter :get_assignment, :get_course, :get_question
  load_and_authorize_resource

  # GET /scales
  # GET /scales.json
  def index
    @scales = Scale.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @scales }
    end
  end

  # GET /scales/1
  # GET /scales/1.json
  def show
    @scale = Scale.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @scale }
    end
  end

  # GET /scales/new
  # GET /scales/new.json
  def new
    @scale = Scale.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @scale }
    end
  end

  # GET /scales/1/edit
  def edit
    @scale = Scale.find(params[:id])
  end

  # POST /scales
  # POST /scales.json
  def create
    @scale = Scale.new(params[:scale])

    respond_to do |format|
      if @scale.save
        format.html { redirect_to @scale, notice: 'Scale was successfully created.' }
        format.json { render json: @scale, status: :created, location: @scale }
      else
        format.html { render action: "new" }
        format.json { render json: @scale.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /scales/1
  # PUT /scales/1.json
  def update
    @scale = Scale.find(params[:id])

    respond_to do |format|
      if @scale.update_attributes(params[:scale])
        format.html { redirect_to @scale, notice: 'Scale was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @scale.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scales/1
  # DELETE /scales/1.json
  def destroy
    @scale = Scale.find(params[:id])
    @scale.destroy

    respond_to do |format|
      format.html { redirect_to scales_url }
      format.json { head :no_content }
    end
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

def get_question
  if params[:question_id]
    @question = Question.find(params[:question_id])
  end
end
