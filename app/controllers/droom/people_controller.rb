module Droom
  class PeopleController < Droom::EngineController
    respond_to :json, :html, :js, :vcf
    before_filter :authenticate_user!  
    before_filter :find_people, :only => :index
    before_filter :get_person, :only => [:show, :feed]
    before_filter :confine_to_self, :except => [:index, :show]
    
    def index
      respond_with @people
    end
    
    def show
      respond_with @person
    end
    
  protected
    
    def get_person
      @person = Person.find(params[:id])
    end
    
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
 
    def confine_to_self
      @person = current_user.person unless current_user.admin?
    end

  end
end