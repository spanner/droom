module Droom
  class PreferencesController < Droom::EngineController
    respond_to :js, :html
    layout :no_layout_if_pjax
  
    before_filter :authenticate_user!
    before_filter :get_preference, :only => [:show, :edit, :update]
    before_filter :build_preference, :only => [:new, :create]
    
    def create
      @preference.update_attributes(params[:preference])
      @preference.save
      render :partial => "preference"
    end

    def update
      @preference.update_attributes(params[:preference])
      @preference.save
      render :partial => "preference"
    end
    
  protected
    
    def get_preference
      @preference = current_user.preferences.find(params[:id])
    end

    def build_preference
      key = params[:preference][:key] || params[:key]
      @preference = current_user.preferences.find_or_initialize_by_key(key)
    end
    
  end
end