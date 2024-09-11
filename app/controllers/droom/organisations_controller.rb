module Droom
  class OrganisationsController < Droom::DroomController
    include Droom::Concerns::Searchable
    helper Droom::DroomHelper
    respond_to :html

    load_and_authorize_resource except: [:registerme, :register]
    before_action :set_view, only: [:show, :edit, :update, :create]
    
    skip_before_action :authenticate_user!, only: [:registerme, :register, :propose], raise: false
    skip_before_action :check_user_setup, only: [:registerme, :register, :propose], raise: false
    before_action :validate_registration_email, only: [:register, :propose]

    rescue_from Droom::EmailConfirmationRequired, with: :invalid_registration

    def show
      raise ActiveRecord::RecordNotFound unless admin? || @organisation.approved?
      render
    end

    def index
      @external = params[:external] unless params[:external] == 'false'
      if pjax?
        render partial: "droom/organisations/list", locals: {organisations: @organisations}
      else
        render
      end
    end

    def pending
      @organisations = Droom::Organisation.pending
      render
    end

    def create
      @organisation.update(organisation_params)
      @organisation.approve!(current_user)
      respond_with @organisation
    end

    def update
      @organisation.update(organisation_params)
      @organisation.approve!(current_user)
      respond_with @organisation
    end


    # ** REGISTRATION
    # proposal of new organisation by anonymous or known user
    #
    # `registerme` generates a link and sends it to the given email address
    # the link includes hashed confirmation of the email, so that it cannot subsequently be changed.
    def registerme
      if Droom.config.invite_organisation_registration? && registerme_params[:email].present?
        Droom::Mailer.org_registration_invitation(registerme_params[:email]).deliver_now
        render partial: "droom/organisations/registration_invitation_sent"
      else
        head :not_acceptable
      end
    end

    # `register` displays a blank registration form
    # after validating email by hashed confirmation token.
    # spammy requests have been discarded with :not_acceptable
    def register
      @organisation = Droom::Organisation.new(registration_params)
      @organisation.build_owner(email: registration_params[:registration_email])
      render
    end

    # `propose` completes registration and saves the proposed organisation
    # validates email confirmation token again
    # if it's one we already know, the existing user account will take ownership of the proposed organisation.
    # spammy requests have been discarded with :not_acceptable
    def propose
      # patch in the validated email param
      # build new organisation with external markings
      @organisation = Droom::Organisation.new
      @organisation.assign_attributes(registration_params)
      @organisation.external = true
      @email = CGI.unescapeURIComponent(registration_params[:registration_email])
      if existing_user = Droom::User.from_email(@email).first
        @organisation.owner = existing_user
      else
        @organisation.build_owner
        # new user account will be created, but with no rights yet
        @organisation.owner.email = @email
        @organisation.owner.given_name = @organisation.registration_given_name
        @organisation.owner.family_name = @organisation.registration_family_name
        @organisation.owner.phone = @organisation.registration_phone
        @organisation.owner.role = @organisation.registration_role
        @organisation.owner.requires_approval = true
      end

      if @organisation.valid?
        @organisation.save!
        @organisation.owner.save!
        @user = @organisation.owner
        Droom::Mailer.org_confirmation(@organisation).deliver_later
        Droom::User.gatekeepers.each do |user|
          Droom::Mailer.org_notification(@organisation, user).deliver_later
        end
        render template: "droom/organisations/registered"
      else
        render action: :register
      end
    end

    # admin actions in response to registration
    def approve
      @organisation.approve!(current_user)
      redirect_to organisation_url
    end

    def disapprove
      @organisation.disapprove!(current_user)
      redirect_to organisation_url
    end


    # ** HOUSEKEEPING
    # always an ajax call so for now we only confirm.
    def merge
      @other_org = Droom::Organisation.find(merge_params[:other_id])
      @other_org.subsume(@organisation)
      head :no_content
    end

    def destroy
      @organisation.destroy
      head :ok
    end

    def invalid_registration
      head :not_acceptable
    end

  protected

    def organisation_params
      if params[:organisation]
        params.require(:organisation).permit(:name, :description, :keywords, :owner, :owner_id, :chinese_name, :phone, :address, :organisation_type_id, :url, :facebook_page, :twitter_id, :instagram_id, :weibo_id, :image, :logo, :external, :joinable, :email_domain, tag_ids: [], administrator_ids: [])
      else
        {}
      end
    end

    def registerme_params
      params.permit(:email)
    end

    def registration_params
      if params[:organisation]
        params.require(:organisation).permit(:name, :description, :keywords, :chinese_name, :organisation_type_id, :url, :registration_given_name, :registration_family_name, :registration_phone, :registration_role, :registration_email, :registration_email_token)
      end
    end

    def merge_params
      params.require(:organisation).permit(:other_id)
    end

    def set_view
      @view = params[:view] if %w{page listed gridded quick full status users pending subsume}.include?(params[:view])
    end

    ## Searchable configuration
    #
    def search_fields
      ['name^10', 'chinese_name', 'description', 'url', 'address', 'people']
    end

    def search_highlights
      {tag: "<strong>"}
    end

    def search_default_sort
      "name"
    end

    def search_criterion_params
      [:external]
    end

    def non_admin_filter
      { approved: true }
    end

    # Organisation registration is allowed to unregistered users and is not authorized in the usual way,
    # but we start with an email round trip and then carry the email validation through the rest of the process.
    #
    def validate_registration_email
      @email = CGI.unescapeURIComponent(registration_params[:registration_email])
      @token = CGI.unescapeURIComponent(registration_params[:registration_email_token])
      Rails.logger.warn("✋ validate_registration_email: #{@email} vs #{@token}")
      if @email.blank? || @token.blank?
        Rails.logger.warn("✋  something missing")
        raise Droom::EmailConfirmationRequired
      end
      check_token = Devise.token_generator.digest(Droom::User, 'email', @email)
      if check_token != @token
        Rails.logger.warn("✋  token not ok")
        raise Droom::EmailConfirmationRequired
      end
    end

  end
end