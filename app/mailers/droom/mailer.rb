module Droom
  class Mailer < ActionMailer::Base
    layout Droom.email_layout
    default from: Droom.email_from

    def login_link(user)
      @user = user
      @subject = I18n.t("login_message.subject")
      mail(to: @user.email, subject: @subject)
    end
  end
end