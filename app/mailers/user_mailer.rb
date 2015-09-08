class UserMailer < ActionMailer::Base
  PROD_URL = "coursemark.org"      # This should be coursemark.org, but the proxy isn't working
  DEV_URL = "localhost:3000"
  PROTOCOL = 'http'

  default from: "james.morris@cmu.edu"
  #ActionMailer::Base.raise_delivery_errors = false  # until I figure out how to catch

  # Constants
  AUTOGEN_MSG = "This is an autogenerated email from coursemark.org.
                 There is no need to reply to this email."

  def welcome_email(user, password, course)
    @user = user
    @password = password
    @course = course
    @autogen_msg = AUTOGEN_MSG
    mail(to: user.email, subject: "Welcome to #{@course.name}")
  end

  def welcome_email_walk_on(user)
    @user = user

    @url =  confirm_email_url(host: if Rails.env.production? then PROD_URL else DEV_URL end,
                              id: user.id,
                              confirmation_token: user.confirmation_token,
                              protocol: "http" )

    mail(to: user.email, subject: "Welcome to Coursemark")
  end

  def registration_email(user, course)
    @user = user
    @course = course
    @autogen_msg = AUTOGEN_MSG
    mail(to: user.email, subject: "Welcome to #{@course.name}")
  end

  def error_email(error, user, email)
    @sender = user
    @error = error
    @email = email
    @autogen_msg = AUTOGEN_MSG
    @signin_url = signin_url(protocol: "http", host: Rails.env.production? ? PROD_URL : DEV_URL)

    mail(to: @sender.email, subject: "Error: #@error")
  end

  def password_reset(user)
    @user = user
    @autogen_msg = AUTOGEN_MSG

    @url =  reset_password_url(host: if Rails.env.production?
                                       PROD_URL
                                     else
                                       DEV_URL
                                     end,
                               id: user.id,
                               confirmation_token: user.confirmation_token,
                               protocol: 'http')
    mail(to: user.email, subject: "Request for Password Reset")
  end

end
