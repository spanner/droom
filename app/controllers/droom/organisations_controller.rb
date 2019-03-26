module Droom
  class OrganisationsController < Droom::EngineController
    include Droom::Concerns::Searchable
    helper Droom::DroomHelper

    respond_to :html, :js
    layout :no_layout_if_pjax

    skip_before_action :authenticate_user!, only: [:signup, :register]
    load_and_authorize_resource except: [:signup, :register]
    before_action :set_view, only: [:show, :edit, :update, :create]

    def show
      unless admin?
        raise ActiveRecord::RecordNotFound unless @organisation.approved?
      end
      render
    end

    def index
      @external = params[:external] unless params[:external] == 'false'
      render
    end

    def pending
      @organisations = Droom::Organisation.pending
      render
    end

    def create
      @organisation.update_attributes(organisation_params)
      @organisation.approve!(current_user)
      respond_with @organisation
    end

    def signup
      if Droom.organisations_registerable?
        if @page = Droom::Page.published.find_by(slug: "_signup")
          render template: "droom/pages/published", layout: Droom.page_layout
        else
          @organisation = Droom::Organisation.new
          render
        end
      else
        head :not_allowed
      end
    end

    def register
      if Droom.organisations_registerable?
        @organisation = Droom::Organisation.from_signup registration_params
        @user = @organisation.owner
        @organisation.send_registration_confirmation_messages
        render
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

    def merge
      @other_org = Droom::Organisation.find(params[:other_id])
      @other_org.subsume(@organisation)
      head :no_content
    end

    def destroy
      @organisation.destroy
      head :ok
    end

  protected

    def organisation_params
      if params[:organisation]
        params.require(:organisation).permit(:name, :description, :keywords, :owner, :owner_id, :chinese_name, :phone, :address, :organisation_type_id, :url, :facebook_page, :twitter_id, :instagram_id, :weibo_id, :image, :logo, :external, :joinable, :email_domain, administrator_ids: [])
      else
        {}
      end
    end

    def registration_params
      if params[:organisation]
        params.require(:organisation).permit(:name, :description, :keywords, :chinese_name, :organisation_type_id, :url, owner: [:given_name, :family_name, :chinese_name, :email])
      else
        {}
      end
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

  end
end