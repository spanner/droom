require 'mustache'

module Droom
  class Page < ApplicationRecord
    include Droom::Concerns::Slugged
    include Droom::Concerns::Published

    before_validation :slug_from_title

    def interpolations
      itp = {
        site_title: I18n.t('site_title'),
        sign_in_link: sign_in_link,
        sign_in_button: sign_in_button
      }
      if Droom.organisations_registerable?
        itp.merge!({
          user_count: Droom::User.count,
          organisation_count: Droom::Organisation.count,
          sign_up_link: sign_up_link,
          sign_up_button: sign_up_button,
          sign_up_form: render_signup_form,
        })
      end
      itp.merge custom_interpolations
    end

    def custom_interpolations
      {}
    end

  def render_fragment(file)
    ApplicationController.renderer.render(partial: "droom/pages/fragments/#{file}").html_safe
  end

  def render_signup_form
    ApplicationController.renderer.render(partial: 'droom/organisations/signup').html_safe
  end

  def sign_in_link
    render_fragment 'sign_in_link'
  end

  def sign_up_link
    render_fragment 'sign_up_link'
  end

  def sign_up_button
    render_fragment 'sign_up_button'
  end

  def sign_in_button
    render_fragment 'sign_in_button'
  end

  end
end
