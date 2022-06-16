require 'net/https'

module Droom::Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :set_access_control_headers
    skip_before_action :verify_authenticity_token, raise: false
    layout :default_layout

    def new
      if Droom.registerable?
        if @page = Droom::Page.published.find_by(slug: "_signup")
          render template: "droom/pages/published", layout: Droom.page_layout
        else
          super
        end
      else
        head :forbidden
      end
    end

    def create
      if helpers.check_recaptcha?
        min_score = 0.5
        secret_key = ENV['RECAPTCHA_SECRET_KEY']
        token = params[:recaptcha_token]

        uri = URI.parse("https://www.google.com/recaptcha/api/siteverify?secret=#{secret_key}&response=#{token}")
        response = Net::HTTP.get_response(uri)
        json = JSON.parse(response.body)
        result = json['success'] && json['score'] > min_score && json['action'] == 'submit'

        unless result
          return redirect_to signup_url
        end
      end
      super
    end

    def after_sign_up_path_for(resource)
      root_url
    end

    def after_inactive_sign_up_path_for(resource)
      confirm_registration_url
    end

    def confirm
      render locals: {resource: @resource}
    end

    def default_layout
      Droom.layout
    end

  end
end