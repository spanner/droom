module Droom
  class EnquiriesController < Droom::EngineController
    respond_to :html, :js
    layout :no_layout_if_pjax

    skip_before_action :authenticate_user!, only: [:new, :create, :show]
    skip_before_action :set_exception_context
    skip_before_action :require_password, only: [:new, :create, :show]
    skip_before_action :note_current_user, only: [:new, :create, :show]

    load_and_authorize_resource

    def index
      limit = params[:limit].presence || 5
      @enquiries = paginated(@enquiries, limit)
      respond_with @enquiries
    end
  
    def show
      respond_with @enquiry
    end

    def new
      @enquiry.request = request
      respond_with @enquiry
    end

    def test
      @enquiry = Droom::Enquiry.new
      @enquiry.request = request
      respond_with @enquiry
    end

    def edit
      respond_with @enquiry
    end

    def update
      @enquiry.update_attributes(enquiry_params)
      respond_with @enquiry
    end

    def create
      @enquiry.request = request
      if @enquiry.update_attributes(enquiry_params)
        render
      else
        render template: 'edit'
      end
    end
  
    def destroy
      @enquiry.destroy
      head :ok
    end

  protected

    def enquiry_params
      params.require(:enquiry).permit(:name, :email, :message, :closed, :robot)
    end

  end
end