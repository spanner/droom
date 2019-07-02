module Droom
  class Page < Droom::DroomRecord
    include Droom::Concerns::Slugged
    include Droom::Concerns::Published

    before_validation :slug_from_title

    def interpolations
      itp = {
        site_title: I18n.t('site_title'),
        sign_in_link: render_fragment('sign_in_link'),
        sign_in_button: render_fragment('sign_in_button'),
        sign_in_form: sign_in_form
      }
      if Droom.registerable?
        itp.merge!({
          user_count: Droom::User.count,
          organisation_count: Droom::Organisation.count,
          sign_up_link: render_fragment('sign_up_link'),
          sign_up_button: render_fragment('sign_up_button'),
          sign_up_form: sign_up_form
        })
      end
      itp.merge custom_interpolations
    end

    def custom_interpolations
      {}
    end

    def render_fragment(file)
      proc {
        ApplicationController.renderer.render(partial: "droom/pages/fragments/#{file}").html_safe
      }
    end

    def sign_up_form
      proc {
        ApplicationController.renderer.render(template: 'devise/registrations/new', layout: false, locals: {resource_name: 'user', resource: Droom::User.new}).html_safe
      }
    end

    def sign_in_form
      proc {
        ApplicationController.renderer.render(partial: 'devise/sessions/login_form', locals: {
          resource: User.new,
          resource_name: "user"
        }).html_safe
      }
    end

  end
end
