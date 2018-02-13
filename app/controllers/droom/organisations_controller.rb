module Droom
  class OrganisationsController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax
    helper Droom::DroomHelper

    skip_before_action :verify_authenticity_token, only: [:register, :signup]
    skip_before_action :authenticate_user!, only: [:register, :signup]
    before_action :search_organisations, only: [:index]
    load_and_authorize_resource except: [:register, :signup]
    before_action :set_view, only: [:show, :edit, :update, :create]

    def show
      unless admin?
        raise ActiveRecord::RecordNotFound if @organisation.disapproved?
      end
      render
    end

    def index
      unless admin?
        @organisations = @organisations.approved
      end
      render
    end

    def pending
      @organisations = Droom::Organisation.unapproved
      render
    end

    def create
      @organisation.update_attributes(organisation_params)
      @organisation.approve!(current_user)
      respond_with @organisation
    end

    def register
      if Droom.organisations_registerable?
        #todo: check that organisation has user, required fields.
        @organisation = Droom::Organisation.create organisation_params
        @user = @organisation.owner
        @organisation.send_registration_confirmation_messages
        respond_with @organisation
      else
        head :not_allowed
      end
    end

    def update
      @organisation.update_attributes(organisation_params)
      respond_with @organisation
    end

    def approve
      @organisation.approve!(current_user)
      redirect_to organisation_url
    end

    def disapprove
      @organisation.disapprove!(current_user)
      redirect_to organisation_url
    end

    def destroy
      @organisation.destroy
      head :ok
    end

  protected

    def organisation_params
      if params[:organisation]
        params.require(:organisation).permit(:name, :description, :owner, :owner_id, :chinese_name, :phone, :address, :organisation_type_id, :url, :facebook_page, :twitter_id, :instagram_id, :weibo_id, :image_date, :image_name, :logo_data, :logo_name, owner_attributes: [:given_name, :family_name, :chinese_name, :email])
      else
        {}
      end
    end

    def set_view
      @view = params[:view] if %w{page listed quick full}.include?(params[:view])
    end

    def search_organisations
      if params[:q].present?
        query = params[:q].presence
        arguments = { order: {_score: :desc}}
      else
        query = '*'
        arguments = { order: {name: :asc}}
      end

      if params[:show] == "all"
        arguments[:limit] = 1000
      else
        arguments[:per_page] = (params[:show].presence || 50).to_i
        arguments[:page] = (params[:page].presence || 1).to_i
      end

      @organisations = Droom::Organisation.search query, arguments
    end

  end
end