module Droom
  class Mailer < ActionMailer::Base

    def org_confirmation(organisation)
      @organisation = organisation
      @user = organisation.owner
      @subject = I18n.t("registration.confirmation_subject", name: organisation.name)
      mail(to: @user.email, subject: @subject)
    end

    def org_notification(organisation)
      @organisation = organisation
      @user = organisation.owner
      @subject = I18n.t("registration.notification_subject", name: organisation.name)
      mail(to: @user.email, subject: @subject)
    end

    def org_welcome(organisation)
      @organisation = organisation
      @user = organisation.owner
      @subject = I18n.t("registration.welcome_subject", name: organisation.name)
      mail(to: @user.email, subject: @subject)
    end

    # def templated_message(user, subject, message_template)
    #   if @page = Droom::Page.find_by(slug: message_template)
    #     @user = user
    #     @subject = subject
    #     @title = I18n.t("email.subjects.#{message_template}".to_sym)
    #     mail(to: @user.email, subject: @title, template_name: message_template)
    #   end
    # end

  end
end