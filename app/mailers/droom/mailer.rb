module Droom
  class Mailer < ActionMailer::Base

    default :from => Droom.email_from, :return_path => Droom.email_return_path
    layout Droom.email_layout
  
    def invitation(user)
      @user = user
      @subject = I18n.t(:invitation_subject)
      mail(:to => "#{@user.name} <#{@user.email}>", :subject => @subject)
    end

  end
end