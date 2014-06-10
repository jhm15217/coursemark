class StaticPagesController < ApplicationController
  skip_before_filter :require_login

  def home
  end

  def help
  end

  def about
  end

  def contact
  end

  def email_confirmation_sent
    redirect_to root_path and return unless params[:id]
    @user = User.find(params[:id])
    render :layout => 'startup_page'
  end

end
