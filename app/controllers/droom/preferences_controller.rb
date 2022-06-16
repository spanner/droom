module Droom
  class PreferencesController < Droom::DroomController
    respond_to :js, :html
    
    before_action :build_preference, :only => [:new, :create]
    load_and_authorize_resource :through => :current_user

    def create
      @preference.update(params[:preference])
      @preference.save
      render :partial => "preference"
    end

    def update
      @preference.update(params[:preference])
      @preference.save
      render :partial => "preference"
    end

  protected

    def build_preference
      key = params[:preference][:key] || params[:key]
      @preference = current_user.preferences.where(:key => key).first_or_initialize
    end

    def preference_parameters
      params.require(:preference).permit(:value, :uuid)
    end

  end
end