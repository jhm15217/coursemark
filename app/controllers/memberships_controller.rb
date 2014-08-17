

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
    @memberships = @assignment.memberships

    params[:response][:teams].split("\r\n").each{ |line| add_teammate(line.split(',')) }

    respond_to do |format|
      format.html { redirect_to course_assignment_memberships_path(@course,@assignment) }
      format.json { render json: @membership, status: :created, location: @membership }
    end
  end

  def add_teammate(row)
    student = User.find_all_by_email(row[2])[0]
    if !student  or !@course.get_students.any?{|s| s.id == student.id }
      if flash[:error]
        flash[:error] << ", #{row[2]}"
      else
        flash[:error] = "Can't find #{row[2]}"
      end
    else
      # Wipe out any previous memberships for this assignment
      @memberships.select{|m| m.user_id == student.id and m.assignment_id = @assignment.id }.each do |membership|
        membership.delete
      end
      # create new pseudo-user if needed
      if !row[3] then row[3] = '' end
      if !row[4] then row[4] = '' end
      pseudo_users = User.all.select{|x| x.pseudo and x.first_name == row[3] and x.last_name == row[4]}

      if pseudo_users.length > 0
        pseudo_user = pseudo_users.first
      else
        pseudo_user = User.new(first_name: row[3], last_name: row[4], email: row[3] + row[4] + '@team.edu',  pseudo: true)
        pseudo_user.save!(validate: false)
        register_pseudo_user(@course.id, pseudo_user)
      end
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

  def register_pseudo_user(course_id,user)
    registration = Registration.new()
    registration.active = true
    registration.instructor = false
    registration.course_id = course_id
    registration.user = user
    # Throw an error if the user is already registered.
    if (Registration.where(:user_id => user.id).length > 0)
      raise ExistingRegistration
    end
    registration.save!
  end


end
