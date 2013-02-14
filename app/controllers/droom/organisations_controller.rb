module Droom
  class OrganisationsController < ApplicationController
    respond_to :html
    layout :no_layout_if_pjax
    helper Droom::DroomHelper
  
    before_filter :authenticate_user!
    before_filter :scale_image_params, :only => [:create, :update]
    before_filter :find_organisations, :only => [:index]
    before_filter :get_organisation, :only => [:show, :edit, :update, :destroy]
    before_filter :build_organisation, :only => [:new, :create]

    def create
      @organisation.update_attributes(params[:organisation])
      respond_with @organisation
    end

    def update
      @organisation.update_attributes(params[:organisation])
      respond_with @organisation
    end

    def show
      respond_with @organisation
    end

    def destroy
      @organisation.destroy
      head :ok
    end

  protected

    def find_organisations
      @show = params[:show] || 10
      @page = params[:page] || 1
      @organisations = Droom::Organisation.page(@page).per(@show)
    end

    def get_organisation
      @organisation = Droom::Organisation.find(params[:id])
    end

    def build_organisation
      @organisation = Droom::Organisation.new(params[:organisation])
    end
  
    def scale_image_params
      multiplier = params[:multiplier] || 4
      [:image_scale_width, :image_scale_height, :image_offset_left, :image_offset_top].each do |p|
        params[:person][p] = (params[:person][p].to_i * multiplier.to_i) unless params[:person][p].blank?
      end
    end
  
  end
end