class UserMailer < ActionMailer::Base
	default :from => "test@gmail.com"
  
  def new_password_instructions(user, admin)
    @user = user
    @admin = admin
    mail(:to => user.email, :subject => "Registered")
  end
end
