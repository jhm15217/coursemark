class PasswordResetsController < ApplicationController

  skip_before_filter :require_login

  def new
    render :layout => 'startup_page'
  end

  # Password reset email is sent
  def create
    @user =  User.find_by_email(params[:email])
    if @user && @user.confirmed
      @user.send_password_reset
      redirect_to email_confirmation_path(id: @user.id), flash: { notice: "Email sent with password reset instructions." }
    else
      flash.now[:error] = "Sorry, that email is not registered"
      render 'new', :layout => 'startup_page'
    end
  end

  def edit
    confirm_user = User.find_by_id(params[:id]) == User.find_by_confirmation_token(params[:confirmation_token])
    if confirm_user
      @user = User.find(params[:id]) if confirm_user
      render :layout => 'startup_page'
    else
      redirect_to login_path, flash: { error: "Something is wrong with your request." }
    end
  end

  def update
    @user = User.find(params[:id])
    if @user.password_reset_sent_at < 1.hour.ago
      redirect_to login_path, flash: { error: "Your password reset has expired." }

    # The following will cause link to expire after one use.
    elsif @user.update_attributes(params[:user])
      @user.password_reset_sent_at = 2.hours.ago and @user.save!(validate: false)
      redirect_to login_path, flash: { success: "Your password has been reset" }
    else
      flash.now[:error] = "Try again, please."
      render :edit, layout: 'startup_page'

    end
  end
end
