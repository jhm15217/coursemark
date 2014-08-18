class UserSessionsController < ApplicationController
  skip_before_filter :require_login
  load_and_authorize_resource except: :login_student

  def new
    #This is the first code executed when the site opens
    unless User.find_by_email('admin@email.com')   # Execute this once after a db reset
      admin = User.new(first_name: 'Mr', last_name: 'Admin', email: 'admin@email.com', password: 'IAmTheAdministrator',
                       password_confirmation: 'IAmTheAdministrator')
      admin.confirmed = true
      admin.save!
    end

    @user_session = UserSession.new

    respond_to do |format|
      format.html { render :layout => 'startup_page' }
      format.json { render json: @course }
    end
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      redirect_to root_url
    else
      render :action => 'new', :layout => 'startup_page'
    end
  end

  def destroy
    $PUPPET = nil
    @user_session = UserSession.find
    if @user_session
      @user_session.destroy
    end
    redirect_to root_url
  end

end
