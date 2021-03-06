

class MembershipsController < ApplicationController
  require 'csv'
  skip_before_filter  :verify_authenticity_token

    # GET /memberships
  # GET /memberships.json
  def index
    @course = Course.find(params[:course_id])
    @assignment = Assignment.find(params[:assignment_id])
    @memberships = @assignment.memberships

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @memberships }
    end
  end

  # GET /memberships/1
  # GET /memberships/1.json
  def show
    @membership = Membership.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @membership }
    end
  end

  # GET /memberships/new
  # GET /memberships/new.json
  def new
    @membership = Membership.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @membership }
    end
  end

  # GET /memberships/1/edit
  def edit
    @membership = Membership.find(params[:id])
  end

  # POST /memberships
  # POST /memberships.json
  # The csv file has no labels and lines of the form [email,team_name]
  def create
    @course = Course.find(params[:course_id])
    @assignment = Assignment.find(params[:assignment_id])
    # Every upload is a complete team designations
    @assignment.memberships(true).each do |membership|
      if !membership.destroy
        puts  "Not destroyed: " + membership.inspect
      end
    end
    params[:response][:teams].split("\r\n" ).each{ |line|
      add_teammate(line.split(',').map{|s| clean_csv_item(s)})
    }

    @course.get_real_students.each do |student|
      if !@assignment.memberships(true).any?{|membership| membership.user_id == student.id }
        multi_flash(:notice, 'Student(s) without a team: ', student.email)
      end
    end


    respond_to do |format|
      format.html { redirect_to course_assignment_memberships_path(@course,@assignment) }
      format.json { render json: @membership, status: :created, location: @membership }
    end
  end

  def get_memberships(assignment)
             Membership.all.select{|membership| membership.assignment_id == assignment.id }
  end

  def multi_flash(tag, m1, m2)
    if flash[tag]
      flash[tag] << ', ' + m2
    else
      flash[tag] = m1 + m2
    end
  end

  def add_teammate(row)     # first_name,last_name,email,first_teamname,last_teamname,
    student = User.find_all_by_email(row[2])[0]
    if !student  or !@course.get_students.any?{|s| s.id == student.id }
      multi_flash(:error, "Can't find ", row[2])
    else
      # create new pseudo-user if needed
      if !row[3] then row[3] = '' end
      if !row[4] then row[4] = '' end
      email = (row[3] + row[4] + '@team.edu').downcase
      pseudo_user = User.all.select{|x| x.pseudo and x.email == email}[0]
      if !pseudo_user
        pseudo_user = User.new(first_name: row[3], last_name: row[4], email: email,  pseudo: true)
        pseudo_user.save!(validate: false)
      end
      register_pseudo_user(@course.id, pseudo_user, student)
      Membership.new(team:pseudo_user.name, user_id: student.id, assignment_id: @assignment.id, pseudo_user_id: pseudo_user.id).save!
    end
  end


# PUT /memberships/1
  # PUT /memberships/1.json
  def update
    @membership = Membership.find(params[:id])

    respond_to do |format|
      if @membership.update_attributes(params[:membership])
        format.html { redirect_to @membership, notice: 'Membership was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @membership.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /memberships/1
  # DELETE /memberships/1.json
  def destroy
    @membership = Membership.find(params[:id])
    @membership.destroy

    respond_to do |format|
      format.html { redirect_to memberships_url }
      format.json { head :no_content }
    end
  end
  private

  def register_pseudo_user(course_id, pseudo_user, student)
    registration = Registration.where(user_id:  pseudo_user.id, course_id: course_id)[0]
    if registration
      registration['section'] =  student.registration_in(Course.find(course_id)).section
    else
      registration = Registration.new(active: true, instructor: false, course_id: course_id, user_id: pseudo_user.id,
                                      section: student.registration_in(Course.find(course_id)).section)
    end
    registration.save!
  end


end
