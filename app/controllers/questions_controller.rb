class QuestionsController < ApplicationController
  before_filter :get_assignment, :get_course
  load_and_authorize_resource

  # GET /questions
  # GET /questions.json
  def index
    if !current_user.instructor?(@course)
      raise CanCan::AccessDenied.new("Not authorized!")
    end

    @questions = @assignment.questions.sort_by{ |q| q.created_at }

    if params[:export_rubric]
      export
    else

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @questions }
      end
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
    if !current_user.instructor?(@course)
      raise CanCan::AccessDenied.new("Not authorized!")
    end

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
    if !current_user.instructor?(@course)
      raise CanCan::AccessDenied.new("Not authorized!")
    end

    if params[:create_rubric]
      ok = create_rubric
    else
      @question = Question.new(params[:question])
      @question.assignment = @assignment
    end

    respond_to do |format|
      if ok or @question.save
        format.html { redirect_to action: "index" }
        format.json { render json: @question, status: :created, location: @question }
      else
        format.html { render action: "new" }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_rubric
    @course = Course.find(params[:course_id])
    @assignment = Assignment.find(params[:assignment_id])
    @questions = @assignment.questions
    ok = true
    params[:response][:questions].split("\r\n").each do |line|
      row = line.split(',')
      question = Question.new(question_text: row[0], question_weight: row[1].to_i, written_response_required:row[2] == 'TRUE',
                              assignment_id: @assignment.id)
      ok = question.save
      i = 3
      while ok and row[i] and row[i+1] do
        scale = Scale.new(description: row[i], value: row[i+1].to_f, question_id: question.id)
        ok = scale.save
        i += 2
      end
    end
    ok
  end

  # PUT /questions/1
  # PUT /questions/1.json
  def update
    if !current_user.instructor?(@course)
      raise CanCan::AccessDenied.new("Not authorized!")
    end

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
    if !current_user.instructor?(@course)
      raise CanCan::AccessDenied.new("Not authorized!")
    end
    
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

  def export
    data = CSV.generate do |csv|
      @questions.each do |q|
        row = [q.question_text, q.question_weight, q.written_response_required]
        q.scales.each do |s|
          row << s.description
          row << s.value
        end
        csv << row
      end
    end
    current_date = "#{Time.now.month}-#{Time.now.day}-#{Time.now.year}"
    send_data(data, :type => 'text/csv', :filename => "#{@assignment.name} (rubric as of #{current_date}).csv")
  end



end
