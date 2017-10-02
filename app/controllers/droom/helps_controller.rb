module Droom
  class HelpsController < Droom::EngineController
    respond_to :html
    load_and_authorize_resource
    before_action :get_view, only: :show
    layout false

    def new
      @help.assign_attributes help_params
      render
    end

    def create
      if @help.update_attributes(help_params)
        redirect_to droom.help_url(@help)
      else
        render action: :new
      end
    end

    def update
      if @help.update_attributes(help_params)
        redirect_to droom.help_url(@help)
      else
        render action: :edit
      end
    end

    def destroy
      @help.destroy
      redirect_to droom.helps_url
    end

    def builtin
      if help_key = params[:help]
        render template: "helps/#{help_key}", layout: "help"
      end
    end

  protected

    def help_params
      params.require(:help).permit(:title, :slug, :category, :main_image_id, :content)
    end

    def get_view
      @view = params[:view] if %w{popup listed full}.include? params[:view]
    end
  end
end