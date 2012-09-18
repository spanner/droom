module Droom
  class PeopleController < Droom::EngineController
    respond_to :json, :html, :js
    before_filter :authenticate_user!  
    before_filter :find_people  
    
    def index
      respond_with @people
    end
    
  protected
    
    def find_people
      @people = Person.scoped({})

      unless params[:q].blank?
        @searching = true
        @people = @people.name_matching(params[:q])
      end
      
      @show = params[:show] || 10
      @page = params[:page] || 1
      @people.page(@page).per(@show)
    end
 
  end
end