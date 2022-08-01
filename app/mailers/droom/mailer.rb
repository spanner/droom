module Droom
  class Mailer < ActionMailer::Base
    layout Droom.email_layout
    default from: Droom.email_from

    def org_confirmation(organisation)
      @organisation = organisation
      @user = organisation.owner
      @subject = I18n.t("registration.confirmation_subject", name: organisation.name)
      mail(to: @user.email, subject: @subject)
    end

    def org_notification(organisation, admin)
      @organisation = organisation
      @admin = admin
      @user = organisation.owner
      @subject = I18n.t("registration.notification_subject", name: organisation.name)
      mail(to: @admin.email, subject: @subject)
    end

    def org_welcome(organisation, token)
      @organisation = organisation
      @user = organisation.owner
      @token = token
      @subject = I18n.t("registration.welcome_subject", name: organisation.name)
      mail(to: @user.email, subject: @subject)
    end

    def login_link(user)
      @user = user
      @subject = I18n.t("login_message.subject")
      mail(to: @user.email, subject: @subject)
    end
  end
end